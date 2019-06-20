import Foundation
import NIO
import ChatCommon

public final class ServerMessageDecoderChannelHandler: ChannelInboundHandler {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ServerMessage

	public init() { }

	public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		var buffer = unwrapInboundIn(data)
		let message = buffer.withUnsafeMutableReadableBytes { (pointer: UnsafeMutableRawBufferPointer) -> ServerMessage? in
			guard let baseAddress = pointer.baseAddress else {
				return nil
			}
			do {
				let decoded = try JSONDecoder().decode(ServerMessage.self, from: Data(bytesNoCopy: baseAddress, count: pointer.count, deallocator: .none))
				return decoded
			}
			catch let err {
				print("> decoding error: \(err)")
			}
			return nil
		}
		if let message = message {
			context.fireChannelRead(self.wrapInboundOut(message))
		}
	}
}
