# Mission: create a chat client

[Quick link to `Network.framework` documentation](https://developer.apple.com/documentation/network)

The client for our chat solution is an iOS application (albeit a simple one, designed to run on iPad). The client connects to the server and talks a simple protocol: client sends `ClientCommand`s, sever replies with `ServerMessage`s. 

The server will accept commands from clients applications that connect to it. It holds the chat rooms, dispatches the messages sent by clients, and supports direct messages between clients.

To talk to the server, you'll use Network.framework's new API, available starting from iOS 12, tvOS 12 and macOS Mojave.

For this project you'll work in the `iOS` directory. If you're stuck or want to check out a hint, the completed project is in the `iOS-Complete` folder.

## Introduction: the simplicity and versatility of Network.framework

Let's discuss Network.framework! It' sa powerful networking API which provides a small but powerful API surface.

Its main components are:

* [`NWEndpoint`](https://developer.apple.com/documentation/network/nwendpoint), an endpoint in a network connection.
* [`NWConnection`](https://developer.apple.com/documentation/network/nwconnection), a bidirectional data connection between a local endpoint and a remote endpoint.
* [`NWListener`](https://developer.apple.com/documentation/network/nwlistener), an object you use to listen for incoming network connections.
* [`NWParameters`](https://developer.apple.com/documentation/network/nwparameters), an object that stores the protocols to use for connections, options for sending data, and network path constraints.

Network.framework also replaces goold old Reachability with [`NWPath`](https://developer.apple.com/documentation/network/nwpath) and [`NWPathMonitor`](https://developer.apple.com/documentation/network/nwpathmonitor). It adds a ton of information and control over the type of connections, network transitions (i.e. wifi to cellular, etc), supports multipath TCP, proxies, TLS, etc etc. We're only going to scratch the surface with this iOS client application.

## Prelude: familiarize yourself with the application

It's a bare-bones chat application, nothing complicated about it. All the communication with the server, and carrying the state of each chat room is not in the `ChatClientService` class. This is where you'll be doing all your network-related work.

To get started, make sure you get the one Pod we need for this application: MessengerKit, a framework that makes it easy to display a chat user interface.

Make sure you have CocoaPods install:
`$ sudo gem install cocoapods`

Then simply update pods from within the iOS folder:
`$ pod update`

## Task 1: setup the necessary bits for NWConnection

You'll need to create an endpoint ([`NWEndpoint`](https://developer.apple.com/documentation/network/nwendpoint)) that describes the server location, and prepare a dispatch queue for your connection to run on. This is done in `init` and above.

## Task 2: fill in the `connect()` method

Create the [`NWConnection`](https://developer.apple.com/documentation/network/nwconnection) object you need in the `connect()` method. Setup a connection state handler by filling the `setupConnectionStateHandler(_:)` method. You'll learn about the various states a connection can be in.

## Task 3: write the code that sends packets

An easy task (as is the rest of this project), you'll fill in the `sendUnframed(command:)` function which sends raw JSON data to the server. 


## Task 4: write the code that receives messages from the server

Reading messages from the server is slightly more involved than writig, but not much. Again you'll appreciate the simplicity of the Network.framework API which really is a joy to work with. Make sure you feel in both the `readNextUnframedMessage(_:)` and `readNextFrameMessage(_:)` methods to first understand the basic of asynchronous reads in Network.framework, and learn how you split multiple reads and chain them together.

## Task 5: move to a framed packet model

One issue with TCP is packet fragmentation: your JSON may not always arrive in a single chunk, depending on how packets get fragmented along the way. To deal with this, we are going to **frame** our JSON: write a small 4-byte header that gives the size of the following JSON data.

To that end, fill in the fill in the `sendFramed(command:)` method which sends a JSON packet prefixed with an `UInt32` (big endian) with the size of the following  JSON data. An easy way to deal with this is to make two successive writes, indicating that the second one is "complete".

Similarly, fill in the `readNextFramedMessage(_:)` method to first read the 4 bytes of the header then read the rest of the data. You'll learn how to read fragmented data.

Before testing, in the Server project you'll want to open the `ServerMain.swift` file and uncomment the line that adds the `FramedMessageCodec`!  Ask me when you reach this stage.

