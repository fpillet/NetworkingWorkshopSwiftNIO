
import Foundation
import NIO

public func startServer(rooms: [String]) -> (MultiThreadedEventLoopGroup, Channel)? {
	// Create an EventLoopGroup that will accept connections. You can dimension its capacity (in number of threads)
	// according to the number of cores your computer has, or simply use a hardcoded value. Remember that each
	// thread (each EventLoop) can support a large number of connections!

	// TODO: create your EventLoopFrom

	// We're going to use a single instance
	// to handle chat exchanges between participants

	// TODO: create your chat handler singleton

	// Bootstrap the server!
	// TODO: let's do it

	do {
		// Bind server to the receiving port to start listening
		// TODO: bind server

		print("Server running - listening on port \(String(describing: chatServer.localAddress))")
		return (group, chatServer)
	}
	catch let err {
		print("Failed bootstrapping server: err=\(err)")
		return nil
	}
}
