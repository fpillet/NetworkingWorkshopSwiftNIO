
import Foundation
import NIO

public func startServer(rooms: [String]) -> (MultiThreadedEventLoopGroup, Channel)? {
	// 1. Create an EventLoopGroup that will accept connections. You can dimension its capacity (in number of threads)
	// according to the number of cores your computer has, or simply use a hardcoded value. Remember that each
	// thread (each EventLoop) can support a large number of connections!

	// TODO: let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)

	// We're going to use a single instance
	// to handle chat exchanges between participants

	// TODO: let globalChatHandler = ServerChatRoomsHandler(rooms: rooms)

	// Bootstrap the server!
	
	let bootstrap = ServerBootstrap(group: group)
		// Specify backlog and enable SO_REUSEADDR for the server itself
		.serverChannelOption(ChannelOptions.backlog, value: 256)
		.serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
		
		// 2. Set the handlers that are applied to the accepted Channels
		.childChannelInitializer { channel in channel.pipeline.addHandlers([
			// TODO: add the handlers you need
			], position: .first)
		}
		
		// Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
		.childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
		.childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
		.childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
		.childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

	do {
		// 3. Bind server to the receiving port to start listening
		
		// TODO: let chatServer = try bootstrap.bind(host: "::1", port: 9999).wait()

		if let localAddress = chatServer.localAddress {
			print("Server running - listening on port \(localAddress)")
		} else {
			print("Inconsistency: server supposed to be started by no local address is available")
		}
		return (group, chatServer)
	}
	catch let err {
		print("Failed bootstrapping server: err=\(err)")
		return nil
	}
}
