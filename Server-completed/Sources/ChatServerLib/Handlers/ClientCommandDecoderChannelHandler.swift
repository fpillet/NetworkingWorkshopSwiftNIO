import Foundation
import NIO
import ChatCommon

public final class ClientCommandDecoderChannelHandler: ChannelInboundHandler {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ClientCommand

	public init() { }

	public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var buffer = unwrapInboundIn(data)
		let command = buffer.withUnsafeMutableReadableBytes { (pointer: UnsafeMutableRawBufferPointer) -> ClientCommand? in
			guard let baseAddress = pointer.baseAddress else {
					return nil
			}
			do {
				let decoded = try JSONDecoder().decode(ClientCommand.self, from: Data(bytesNoCopy: baseAddress, count: pointer.count, deallocator: .none))
				return decoded
			}
			catch let err {
				print("> decoding error: \(err)")
			}
			return nil
		}
		if let cmd = command {
			ctx.fireChannelRead(self.wrapInboundOut(cmd))
		}
	}
}
