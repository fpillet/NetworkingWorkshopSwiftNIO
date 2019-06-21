import Foundation
import NIO

// A simple CODEC that frames / unframes packets by prefixing them with Int32 size (big endian)

enum FramingError: Error {
	case invalidFrameSizeDetected
}

public struct FramedMessageEncoder: MessageToByteEncoder {
	public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = ByteBuffer

	public init() { }

	// MessageToByteEncoder

	public func encode(data: ByteBuffer, out: inout ByteBuffer) throws {
		out.writeInteger(Int32(data.readableBytes), endianness: .big)
		data.withUnsafeReadableBytes { (p) in
			_ = out.writeBytes(p)
		}
	}
}

public struct FramedMessageDecoder: ByteToMessageDecoder {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ByteBuffer
	
	public init() { }
	
	// ByteToMessageDecoder
	
	public var cumulationBuffer: ByteBuffer?
	
	public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
		guard let frameSize = buffer.readInteger(as: Int32.self), buffer.readableBytes >= frameSize else {
			return .needMoreData
		}
		
		// if the announced size is insanely large, data is certainly corrupt
		// there's not much we can do aside closing the connection
		guard buffer.readableBytes < 2_000_000 else {
			buffer.clear()
			context.fireErrorCaught(FramingError.invalidFrameSizeDetected)
			return .needMoreData
		}
		
		context.fireChannelRead(self.wrapInboundOut(buffer.readSlice(length: Int(frameSize))!))
		return .continue
	}
	
	public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
		return .continue
	}
}
