//
//  WebSocketServer.swift
//  WebSocketServer
//
//  Created by Khazan on 2023/4/17.
//

import Foundation
import NIOCore
import NIOPosix
import NIOHTTP1
import NIOWebSocket

public protocol WebSocketServerDelegate {
    
    func started(on IPAddress: String)  -> Void
    
    func didReceive(text: String) -> Void
}


var GlobalIPAddress = ""


public class WebSocketServer: NSObject {
    
    var channel: Channel?
    
    var client: WebSocketHandler?
    
    public var delegate: WebSocketServerDelegate?
    
    public func start(with delegate: WebSocketServerDelegate, port: Int) -> Void {
        self.delegate = delegate
        
        var IPAddress: String?
        
        NetworkInterface.enumerate().forEach { interface in
            print("interface: \(interface)")
            if interface.name == "en0" && interface.ip.components(separatedBy: ".").count == 4 {
                IPAddress = interface.ip
            }
            if interface.name == "en3" && interface.ip.components(separatedBy: ".").count == 4 {
                IPAddress = interface.ip
            }
            if interface.name == "bridge100" && interface.ip.components(separatedBy: ".").count == 4 {
                IPAddress = interface.ip
            }
        }
        
        guard let IPAddress = IPAddress else {
            return
        }
        
        GlobalIPAddress = IPAddress
        
        let queue = DispatchQueue(label: "websocketserver", qos: .background)
        
        queue.async {
            self.start(on: IPAddress, port: port)
        }
        
    }
    
    
    private func start(on IPAdress: String, port: Int) -> Void {
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let upgrader = NIOWebSocketServerUpgrader(shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in
            channel.eventLoop.makeSucceededFuture(HTTPHeaders()) },
                                                  upgradePipelineHandler: { (channel: Channel, _: HTTPRequestHead) in
            
            let client = WebSocketHandler()
            client.delegate = self
            self.client = client
            
            return channel.pipeline.addHandler(client)
        })
        
        let bootstrap = ServerBootstrap(group: group)
        // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                let httpHandler = HTTPHandler()
                let config: NIOHTTPServerUpgradeConfiguration = (
                    upgraders: [ upgrader ],
                    completionHandler: { _ in
                        channel.pipeline.removeHandler(httpHandler, promise: nil)
                    }
                )
                return channel.pipeline.configureHTTPServerPipeline(withServerUpgrade: config).flatMap {
                    channel.pipeline.addHandler(httpHandler)
                }
            }
        
        // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        defer {
            try! group.syncShutdownGracefully()
        }
        
        do {
            self.channel = try bootstrap.bind(host: IPAdress, port: port).wait()
        } catch {
            print(error)
        }
        
        guard let localAddress = channel?.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        print("Server started and listening on \(localAddress)")
        
        try? self.channel?.closeFuture.wait()
        
        DispatchQueue.main.async {
            self.delegate?.started(on: IPAdress)
        }
        
    }
    
    public func stop() -> Void {
        self.delegate = nil
        self.channel?.close()
    }
    
    public func send(text: String) -> Void {
        self.client?.write(text: text)
    }
    
}


extension WebSocketServer: WebSocketHandlerDelegate {
    
    func didReceive(text: String) {
        if text == "Hi!" {
            send(text: "Hello!")
        }
        
        DispatchQueue.main.async {
            self.delegate?.didReceive(text: text)
        }
    }
    
}
