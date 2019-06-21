# Mission: create a chat client

[Quick link to `Network.framework` documentation](https://developer.apple.com/documentation/network)

The client for our chat solution is an iOS application (albeit a simple one, designed to run on iPad). The client connects to the server and talks a simple protocol: client sends `ClientCommand`s, sever replies with `ServerMessage`s. 

The server will accept commands from clients applications that connect to it. It holds the chat rooms, dispatches the messages sent by clients, and supports direct messages between clients.

To talk to the server, you'll use Network.framework's new API, available starting from iOS 12, tvOS 12 and macOS Mojave.

For this project you'll work in the `iOS` directory. If you're stuck or want to check out a hint, the completed project is in the `iOS-Complete` folder.

## You need a running server

Open `Server-Completed`, then from the terminal do a `swift package update` and `swift package generate-xcodeproj`.

Open the generated project and run it. You should have a server ready to accept connections.

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

## All work is done in `ChatClientService.swift`

## Task 1: prepare the `serverEndpoint` variable in `init`

You'll need to create an endpoint ([`NWEndpoint`](https://developer.apple.com/documentation/network/nwendpoint)) that describes the server location, and prepare a dispatch queue for your connection to run on. This is done in `init` and above.

## Task 2: fill in the `connect()` method

Create the [`NWConnection`](https://developer.apple.com/documentation/network/nwconnection) object you need in the `connect()` method.

Follow the TODO items to fill in the code.

## Task 3: fill in the `setupConnectionStateHandler(_:)` function

Setup a connection state handler by filling the `setupConnectionStateHandler(_:)` method. You'll learn about the various states a connection can be in.

Follow the TODO items to fill in the code.

## Task 4: write the code that sends messages to the server

Fill in the `send(command:)` function following the TODO items.

One issue with TCP is packet fragmentation: your JSON may not always arrive in a single chunk, depending on how packets get fragmented along the way. To deal with this, we are going to **frame** our JSON:

1. encode your command to JSON using Codable's `JSONEncoder`
2. prepare a `UInt32` value with the size of the encoded JSON data
3. make the value `bigEndian` (`value.bigEndian`) as the server expects a big endian value
4. send the 4-byte header
5. send the JSON data itself


## Task 5: write the code that receives messages from the server

Reading messages from the server is slightly more involved than writing, but not much.

Again you'll appreciate the simplicity of the Network.framework API which really is a joy to work with.

Fill in the `readNextMessage(_:)`  function, following the TODO items.
