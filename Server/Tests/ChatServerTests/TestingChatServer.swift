//
//  TestingChatServer.swift
//  ChatServerTests
//
//  Created by Florent Pillet on 26/11/2018.
//

import Foundation
import NIO
import ChatCommon
import ChatServerLib

func setupChatServer(rooms: [String]) -> (MultiThreadedEventLoopGroup, Channel) {
	let group = MultiThreadedEventLoopGroup(numberOfThreads: 2)

	let globalChatHandler = ServerChatRoomsHandler(rooms: rooms)

	let bootstrap = ServerBootstrap(group: group)
		.serverChannelOption(ChannelOptions.backlog, value: 256)
		.serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
		.childChannelInitializer { channel in
			channel.pipeline.addHandlers([
				MessageToByteHandler(FramedMessageEncoder()),
				ByteToMessageHandler(FramedMessageDecoder()),
				ClientCommandDecoderChannelHandler(),
				MessageToByteHandler(ServerMessageEncoder()),
				globalChatHandler], position: .first)
		}
		.childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
		.childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
		.childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
		.childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

	let channel = try! bootstrap.bind(host: "::1", port: testPort).wait()

	return (group, channel)
}

func tearDownServer(_ server: (MultiThreadedEventLoopGroup, Channel)) {
	server.0.shutdownGracefully { error in
		if let error = error {
			print("Shutdown failed with error \(error)")
		} else {
			try! server.1.closeFuture.wait()
		}
	}
}
