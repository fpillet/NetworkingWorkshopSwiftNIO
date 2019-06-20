import XCTest
import NIO
import ChatCommon
import ChatServerLib

fileprivate typealias MessageRecorder = (ServerMessage) -> Void

fileprivate final class ServerMessageRecorder: ChannelInboundHandler {
	typealias InboundIn = ServerMessage
	private let recorder: MessageRecorder

	init(recorder: @escaping MessageRecorder) {
		self.recorder = recorder
	}

	func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		recorder(unwrapInboundIn(data))
	}
}

// A chat client (written with SwiftNIO) we use to connect and run the tests

final class ChatClient {
	enum ChatClientError: Error {
		case responseTimeout
	}

	private let lock = NSLock()
	private var backlog = [ServerMessage]()
	private var expectations = [EventLoopPromise<ServerMessage>]()
	private let channel: Channel

	static func connect(host: String, port: Int, group: EventLoopGroup) -> EventLoopFuture<ChatClient> {
		let bootstrap = ClientBootstrap(group: group)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer { channel in
				channel.pipeline.addHandlers([
					MessageToByteHandler(FramedMessageEncoder()),
					ByteToMessageHandler(FramedMessageDecoder()),
					ServerMessageDecoderChannelHandler()
					], position: .first)
		}
		return bootstrap.connect(host: host, port: port)
			.flatMap { channel in
				let client = ChatClient.init(channel: channel)
				let future = channel.eventLoop.makeSucceededFuture(client)
				let recorder = ServerMessageRecorder(recorder: { [weak client] message in client?.record(message: message) })
				return channel.pipeline
					.addHandler(recorder)
					.flatMap {
						future
				}
		}
	}

	private init(channel: Channel) {
		self.channel = channel
	}

	func close() throws {
		let promise: EventLoopPromise<Void> = channel.eventLoop.makePromise()
		channel.close(promise: promise)
		try promise.futureResult.wait()
	}

	func send(_ command: ClientCommand) throws -> EventLoopFuture<Void> {
		let future = try channel.send(command)
		future.whenFailure { error in XCTFail("Sending command \(command) failed with error \(error)") }
		return future
	}

	func record(message: ServerMessage) {
		lock.lock()
		defer { lock.unlock() }
		if !expectations.isEmpty {
			let promise = expectations.removeFirst()
			promise.succeed(message)
		} else {
			backlog.append(message)
		}
	}

	func expect(_ count: Int = 1, timeout: Int = 1) -> EventLoopFuture<[ServerMessage]> {
		return EventLoopFuture.reduce(into: [ServerMessage](),
									  (0 ..< count).map { _ in expect(timeout: timeout) },
									  on: channel.eventLoop) { ( array:inout [ServerMessage], message: ServerMessage) in
			array.append(message)
		}
	}

	func skip(_ count: Int = 1, timeout: Int = 1) -> EventLoopFuture<Void> {
		return expect(count, timeout: timeout).map { _ in }
	}

	func expect(timeout: Int) -> EventLoopFuture<ServerMessage> {
		lock.lock()
		defer { lock.unlock() }
		if !backlog.isEmpty {
			return channel.eventLoop.makeSucceededFuture(backlog.removeFirst())
		}
		let promise: EventLoopPromise<ServerMessage> = channel.eventLoop.makePromise()
		expectations.append(promise)
		let timeoutTask = channel.eventLoop.scheduleTask(in: .seconds(Int64(timeout))) {
			promise.fail(ChatClientError.responseTimeout)
		}
		let future = promise.futureResult
		future.whenComplete { _ in
			timeoutTask.cancel()
		}
		return future
	}
}
