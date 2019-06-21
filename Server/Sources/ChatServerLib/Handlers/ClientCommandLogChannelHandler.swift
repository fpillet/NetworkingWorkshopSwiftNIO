import Foundation
import NIO
import ChatCommon

public final class ClientCommandLogChannelHandler: ChannelInboundHandler {

	public typealias InboundIn = ClientCommand
	public typealias InboundOut = ClientCommand

	public init() {}

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		// TODO: unwrap data to ClientCommand and log it
		
		
		// carry on to next handler
		context.fireChannelRead(data)
	}
}
