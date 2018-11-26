import Foundation
import NIO
import ChatCommon

public final class ClientCommandLogChannelHandler: ChannelInboundHandler {
	public typealias InboundIn = ClientCommand
	public typealias InboundOut = ClientCommand

	public var username = ""

	public init() {}

	public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		// unwrap data to ClientCommand
		let command = unwrapInboundIn(data)

		// remember the user's name
		if case .connect(let username) = command {
			self.username = username
		}

		// log the command
		let source: String
		if username.isEmpty, let remote = ctx.remoteAddress {
			source = remote.description
		} else {
			source = username
		}

		print("Received from \(source): \(command)")

		// carry on to next handler
		ctx.fireChannelRead(data)
	}
}
