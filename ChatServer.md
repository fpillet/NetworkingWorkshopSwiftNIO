# Mission: create a chat server

We're going to build a simple chat server that can run on macOS and Linux, using Swift-NIO.

The server will accept commands from clients applications that connect to it. It holds the chat rooms, dispatches the messages sent by clients, and supports direct messages between clients.

To simplify the development, most of the infrastructure you need (model, utilities, general project structure) is ready for you to start with.

For this project you'll work in the `Server` directory. If you're stuck or want to check out a hint, the completed project is in the `Server-Complete` folder.

## Prelude: environment setup

The chat server relies on Swift-NIO, which can be obtained using the Swift Package Manager. Firer up a terminal, `cd` to the `Server` folder and run these commands:

`$ swift package update`

then

`$ swift package generate-xcodeproj`

A new `ChatServer.xcodeproj` project will appear in the Server folder.

## Introduction: understanding Swift-NIO's general model

Let's discuss Swift-NIO architecture! The introduction on the repository states that:

> SwiftNIO is a cross-platform asynchronous event-driven network application framework for rapid development of maintainable high performance protocol servers & clients.
> It's like Netty, but written for Swift.

I'll go with you over the main concepts and building blocks in Swift-NIO:

* `EventLoop` and `EventLoopGroup`: 
* `Channel`, a protocol
* `ChannelHandler` and `ChannelPipeline`: single-purpose data handlers and pipelines to assemble them together
* `ServerBootstrap`, `ClientBootstrap` and `DatagramBootstrap`: helpers to quickly get setup for a server or client
* `EventLoopFuture` and `EventLoopPromise`, asynchronous production of results
* `ByteBuffer`, high performance contiguous storage

In this introduction and simple server development, we'll focus on the 5 first items, and will make light use of `Future` to setup the server.

Let me go over Swift-NIO's model, then we'll kick in the first task.

## Task 1: write a logging channel handler

Write a simple channel handler named that you'll insert in the processing pipeline and which logs incoming commands from clients. It will take a `ClientCommand` as its in / out type, log what it sees then pass the data on to the next handler.

Open the `ClientCommandLogHandler.swift` file to get going. Remember that what you process needs to be carried on to the next handler in the pipeline!


## Task 1: write the basic packet format encoder and decoder

You'll need at least one channel handler that decodes the JSON to `ClientCommand` enums, and one that encodes outgoing messages from `ServerCommand` enums.

Remember that data goes in but also needs to get carried out to the next handler in the pipeline.

Open the `ClientCommandDecoderChannelHandler.swift` file to get going with the incoming data decoder.

Next, open `ServerMessageEncoderChannelHandler.swift` to code the outgoing handler. Notice that this time, it will adopt the `MessageToByteEncoder` protocol, worth to know about!


## Task 3: create an EventLoopGroup

An easy one to get started with the actual server. Open `ServerMain.swift` and create your new group.


## Task 4: boostrap the server

This one is more involved as you'll have to understand what `ServerBoostrap` does and how to use it. This all happens in `ServerMain.swift`.

Hints at what you want to do:

* Create a `ServerBootstrap` for your EventLoopGroup
* Set options for the main server channel (the one that listens to client connections). Look into the various `ChannelOptions` and pick the ones you need
* Setup a child channel initializer which will configure the processing pipeline for client connections. At a minimum, you'll want to decode JSON to actual `ClientCommand` instances,
* Add the second channel handler which will log the decoded client commands

At this stage you should be able to start your server, although it won't do much besides logging what comes in. You should be able to test it by running the iOS client and see one incoming message upon connection.


## Task 5: create the actual Chat handler channel

You are now at a point where you're ready to inject the actual functionality of your server: 

- It needs to be a ChannelHandler that will come late in the pipeline
- It must receive `ClientCommand` objects
- It must send `ServerMessage` objects to clients

Start by opening the file `ServerMain.swift` then fill the gaps in the `startServer(rooms:)`function.

## Task #6: run the tests

The tests have already been written for you. If you run tests, either from Xcode or from the commandline, they should mostly pass. "Mostly" because you'll quickly realize that there is one issue left that needs to be taken care of ...

See, TCP doesn't guarantee that everything that's being sent from one side will arrive in a single piece on the other side. There may be packet fragmentation, which means (and this happens during testing, which establishes real connections internally) that you may have JSON packets that arrive in several pieces.

The solution to tackle this issue is to frame your packets in a way that make it easy from the receiving end to reassemble, regardless of the number of chunks they have been split into.

So you'll want to implement a simple framing protocol: send 4 bytes with the length of the data, followed by the data (the JSON representation) itself.

Open the `FrameMessageDecoder.swift` file and get going if you feel you can do it! Otherwise, you'll find a reference implementation in the complete product source code.

Once you've coded this part, make sure you uncomment the lines about `FrameMessageCodec` in `TestingChatClient.swift` and `TestingChatServer.swift` !

That's all for the server. Congrats for making it this far!