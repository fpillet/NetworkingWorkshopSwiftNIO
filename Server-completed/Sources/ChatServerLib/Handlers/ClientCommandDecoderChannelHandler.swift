import Foundation
import NIO
import ChatCommon

public final class ClientCommandDecoderChannelHandler: ChannelInboundHandler {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ClientCommand

	public init() { }

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		var buffer = unwrapInboundIn(data)
		let data = Data(buffer.readBytes(length: buffer.readableBytes)!)
		if let command = try? JSONDecoder().decode(ClientCommand.self, from: data) {
			context.fireChannelRead(self.wrapInboundOut(command))
		}
	}
}
