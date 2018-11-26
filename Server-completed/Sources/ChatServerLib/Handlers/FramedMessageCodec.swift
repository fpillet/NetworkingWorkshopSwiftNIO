import Foundation
import NIO

// A simple CODEC that frames / unframes packets by prefixing them with Int32 size (big endian)

public final class FramedMessageCodec: ByteToMessageDecoder, MessageToByteEncoder {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ByteBuffer

	public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = ByteBuffer

	public init() { }

	// ByteToMessageDecoder
	public var cumulationBuffer: ByteBuffer?

	public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
		guard let frameSize = buffer.getInteger(at: 0, endianness: .big, as: Int32.self), buffer.readableBytes >= frameSize else {
			return .needMoreData
		}
		buffer.moveReaderIndex(forwardBy: MemoryLayout<Int32>.size)
		ctx.fireChannelRead(self.wrapInboundOut(buffer.readSlice(length: Int(frameSize))!))
		return .continue
	}

	// MessageToByteEncoder

	public func encode(ctx: ChannelHandlerContext, data: ByteBuffer, out: inout ByteBuffer) throws {
		out.write(integer: Int32(data.readableBytes), endianness: .big)
		data.withUnsafeReadableBytes { p in
			_ = out.write(bytes: p)
		}
	}
}
