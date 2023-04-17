//
//  WebSocketHandler.swift
//  WebSocketServer
//
//  Created by khazan on 2023/4/14.
//

import Foundation
import UIKit
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOWebSocket

protocol WebSocketHandlerDelegate {
    
    func didReceive(text: String) -> Void
    
}

final class WebSocketHandler: ChannelInboundHandler {
    
    var delegate: WebSocketHandlerDelegate?
    
    typealias InboundIn = WebSocketFrame
    typealias OutboundOut = WebSocketFrame

    private var awaitingClose: Bool = false

    var context: ChannelHandlerContext?
    
    func write(text: String) -> Void {
        guard let context = context else { return }
        
        guard context.channel.isActive else { return }

        guard !self.awaitingClose else { return }
 
        var buffer = context.channel.allocator.buffer(capacity: 12)
        buffer.writeString(text)

        let frame = WebSocketFrame(fin: true, opcode: .text, data: buffer)
        
        context.writeAndFlush(self.wrapOutboundOut(frame)).map {
            
        }.whenFailure { (_: Error) in
            context.close(promise: nil)
        }
    }
    
    public func handlerAdded(context: ChannelHandlerContext) {
        self.context = context
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let frame = self.unwrapInboundIn(data)

        switch frame.opcode {
        case .connectionClose:
            self.receivedClose(context: context, frame: frame)
        case .ping:
            self.pong(context: context, frame: frame)
        case .text:
            var data = frame.unmaskedData
            let text = data.readString(length: data.readableBytes) ?? ""
            print(text)
            
            self.delegate?.didReceive(text: text)
        case .binary, .continuation, .pong:
            // We ignore these frames.
            break
        default:
            // Unknown frames are errors.
            self.closeOnError(context: context)
        }
    }

    public func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    
    private func receivedClose(context: ChannelHandlerContext, frame: WebSocketFrame) {
        // Handle a received close frame. In websockets, we're just going to send the close
        // frame and then close, unless we already sent our own close frame.
        if awaitingClose {
            // Cool, we started the close and were waiting for the user. We're done.
            context.close(promise: nil)
        } else {
            // This is an unsolicited close. We're going to send a response frame and
            // then, when we've sent it, close up shop. We should send back the close code the remote
            // peer sent us, unless they didn't send one at all.
            var data = frame.unmaskedData
            let closeDataCode = data.readSlice(length: 2) ?? ByteBuffer()
            let closeFrame = WebSocketFrame(fin: true, opcode: .connectionClose, data: closeDataCode)
            _ = context.write(self.wrapOutboundOut(closeFrame)).map { () in
                context.close(promise: nil)
            }
        }
    }

    private func pong(context: ChannelHandlerContext, frame: WebSocketFrame) {
        var frameData = frame.data
        let maskingKey = frame.maskKey

        if let maskingKey = maskingKey {
            frameData.webSocketUnmask(maskingKey)
        }

        let responseFrame = WebSocketFrame(fin: true, opcode: .pong, data: frameData)
        context.write(self.wrapOutboundOut(responseFrame), promise: nil)
    }

    private func closeOnError(context: ChannelHandlerContext) {
        // We have hit an error, we want to close. We do that by sending a close frame and then
        // shutting down the write side of the connection.
        var data = context.channel.allocator.buffer(capacity: 2)
        data.write(webSocketErrorCode: .protocolError)
        let frame = WebSocketFrame(fin: true, opcode: .connectionClose, data: data)
        context.write(self.wrapOutboundOut(frame)).whenComplete { (_: Result<Void, Error>) in
            context.close(mode: .output, promise: nil)
        }
        awaitingClose = true
    }
    
}

