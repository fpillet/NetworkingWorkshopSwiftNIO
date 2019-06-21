# Mission: create a chat server

[Quick link to `Swift-NIO` documentation](https://apple.github.io/swift-nio/docs/current/NIO/index.html)

We're going to build a simple chat server that can run on macOS and Linux, using Swift-NIO.

The server will accept commands from clients applications that connect to it. It holds the chat rooms, dispatches the messages sent by clients, and supports direct messages between clients.

To simplify the development, most of the infrastructure you need (model, utilities, general project structure) is ready for you to start with.

For this project you'll work in the `Server` directory. If you're stuck or want to check out a hint, the completed project is in the `Server-Complete` folder.

## Prelude: environment setup

The chat server relies on Swift-NIO, which can be obtained using the Swift Package Manager. Fire up a terminal, `cd` to the `Server` folder and run these commands:

`$ swift package update`

then

`$ swift package generate-xcodeproj`

A new `ChatServer.xcodeproj` project will appear in the Server folder.

You will also need a client to connect from. In the `iOS-Completed` folder you'll find a working client. Make sure you `pod install` first then open the workspace and run the project.

## Introduction: understanding Swift-NIO's general model

Let's discuss Swift-NIO architecture! The introduction on the repository states that:

> SwiftNIO is a cross-platform asynchronous event-driven network application framework for rapid development of maintainable high performance protocol servers & clients.
> It's like Netty, but written for Swift.

I'll go with you over the main concepts and building blocks in Swift-NIO:

* [`EventLoop`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/EventLoop.html) and [`EventLoopGroup`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/EventLoopGroup.html): the main processing loops for Swift-NIO
* [`Channel`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/Channel.html), a protocol
* `ChannelHandler`, [`ChannelInboundHandler`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/ChannelInboundHandler.html), [`ChannelOutboundHandler`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/ChannelOutboundHandler.html) and [`ChannelPipeline`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/ChannelPipeline.html): single-purpose data handlers and pipelines to assemble them together
* [`ServerBootstrap`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/ServerBootstrap.html), [`ClientBootstrap`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/ClientBootstrap.html) and [`DatagramBootstrap`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/DatagramBootstrap.html): helpers to quickly get setup for a server or client
* [`EventLoopFuture`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/EventLoopFuture.html) and [`EventLoopPromise`](https://apple.github.io/swift-nio/docs/current/NIO/Structs/EventLoopPromise.html), asynchronous production of results
* [`ByteBuffer`](https://apple.github.io/swift-nio/docs/current/NIO/Structs/ByteBuffer.html), high performance contiguous storage

In this introduction and simple server development, we'll focus on the 5 first items, and may make light use of `EventLoopFuture` to bootstrap the server.

Let me go over Swift-NIO's model, then we'll kick in the first task.

## Task 1: create an EventLoopGroup

An easy one to get started with the actual server. Open `ServerMain.swift` and create your new group. You need an `EventLoopGroup` to run your server on.


## Task 2: boostrap the server

This one is more involved as you'll have to understand what [`ServerBoostrap`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/ServerBootstrap.html) does and how to use it. This all happens in `ServerMain.swift`.

Hints at what you want to do:

* Create a [`ServerBootstrap`](https://apple.github.io/swift-nio/docs/current/NIO/Classes/ServerBootstrap.html) for your [`EventLoopGroup`](https://apple.github.io/swift-nio/docs/current/NIO/Protocols/EventLoopGroup.html)
* Set options for the main server channel (the one that listens to client connections). Look into the various [`ChannelOption`](https://github.com/apple/swift-nio/blob/master/Sources/NIO/ChannelOption.swift)s and pick the ones you need
* Setup a child channel initializer which will configure the processing pipeline for client connections.  I recommend that you use `channel.pipeline.addHandlers(_:first:)` which is easier to use than the other one shown in the documentation. At a minimum, you will want to insert the `RawLogChannelHandler` there to log data that  goes in an out.

At this stage you should be able to start your server, although it won't do much besides logging what comes in. You should be able to test it by running the iOS client and see one incoming message upon connection.

## Task 3: create the channel handlers that encode and decode ClientCommand to/from JSON

You'll need at least one channel handler that decodes the JSON to `ClientCommand` enums, and one that encodes outgoing messages from `ServerCommand` enums.

Remember that data goes **in** but also needs to get carried **out** to the next handler in the pipeline.

Open the `ClientCommandDecoderChannelHandler.swift` file to get going with the incoming data decoder that decodes the contents of an incoming `ByteBuffer` into `ClientCommand` and passes it to the next handler in the pipeline.

Next, open `ServerMessageEncoderChannelHandler.swift` to code the outgoing handler. Notice that this time, it will adopt the `MessageToByteEncoder` protocol, worth to know about! 


## Task 4: insert the encoder and decoder handlers in the pipeline

Now that you have encoder and decoder handlers, insert them in the pipeline.

First the pipeline need to include the framing encoder and decoders which guarantee that we have a proper envelope around our packets. You'll want to add this to the pipeline first:

```
MessageToByteHandler(FramedMessageEncoder()),
ByteToMessageHandler(FramedMessageDecoder()),
```

Next you add a `RawLogChannelHandler`, which takes a `ByteBuffer` for input.

Finally add the `ClientCommandDecoderChannelHandler` and `ClientCommandEncoderChannelHandler`.

While you're at it, after the `ClientCommandDecoderChannelHandler` you can add the `ClientCommandLogChannelHandler` (already written) that will log properly decoded client commands.

## Task 5: create the actual Chat handler channel

You are now at a point where you're ready to create the actual functionality of your server: 

- It needs to be a ChannelHandler that will come late in the pipeline
- It must receive `ClientCommand` objects
- It must send `ServerMessage` objects to clients
- It must be a singleton because you are going to handle all the connections in a single handler (for easy propagation of messages to all the connections)

Open the `ServerChatRoomsHandler.swift` file to get going then fill in the TODOs.

## Optional: run the tests

The tests have already been written for you. If you run tests, either from Xcode or from the commandline, they should mostly pass. "Mostly" because you'll quickly realize that there is one issue left that needs to be taken care of ...

See, TCP doesn't guarantee that everything that's being sent from one side will arrive in a single piece on the other side. There may be packet fragmentation, which means (and this happens during testing, which establishes real connections internally) that you may have JSON packets that arrive in several pieces.

The solution to tackle this issue is to frame your packets in a way that make it easy from the receiving end to reassemble, regardless of the number of chunks they have been split into.

So you'll want to implement a simple framing protocol: send 4 bytes with the length of the data, followed by the data (the JSON representation) itself.

Once you've coded this part, make sure you uncomment the lines about `FrameMessageCodec` in `TestingChatClient.swift` and `TestingChatServer.swift` !

That's all for the server. Congrats for making it this far!
