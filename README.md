# WebSocketServer

[![CI Status](https://img.shields.io/travis/Khazan@foxmail.com/WebSocketServer.svg?style=flat)](https://travis-ci.org/Khazan@foxmail.com/WebSocketServer)
[![Version](https://img.shields.io/cocoapods/v/WebSocketServer.svg?style=flat)](https://cocoapods.org/pods/WebSocketServer)
[![License](https://img.shields.io/cocoapods/l/WebSocketServer.svg?style=flat)](https://cocoapods.org/pods/WebSocketServer)
[![Platform](https://img.shields.io/cocoapods/p/WebSocketServer.svg?style=flat)](https://cocoapods.org/pods/WebSocketServer)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

WebSocketServer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:


```ruby
pod 'KZLog', :git => 'https://github.com/KhazanGu/WebSocketServer.git'
```


## Author

Khazan@foxmail.com, khazan@foxmail.com

## License

WebSocketServer is available under the MIT license. See the LICENSE file for more info.


## Summary

The WebSocketServer class is an object for management to communicate with clients. 


## Create

Create a server object for management.

```
let server = WebSocketServer()
```

## Start

Run the WebSocket Server on the specified port.

```
server.start(with: self, port: port)
```

## Stop 

Stop the WebSocket Server.

```
server.stop()
```

## Send text

Send text to client.

```
server.send(text: text)
```


## WebSocketServerDelegate

Get the IP address after the server start.

```
func started(on IPAddress: String)  -> Void
```

Receive the text from the client.

```
func didReceive(text: String) -> Void
```
