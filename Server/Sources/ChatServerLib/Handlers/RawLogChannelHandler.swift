import Foundation
import NIO

// This example channel handlers prints incoming and outgoing ByteBuffer contents

public final class RawLogChannelHandler: ChannelInboundHandler, ChannelOutboundHandler {
	public typealias InboundIn = ByteBuffer
	public typealias InboundOut = ByteBuffer

	public typealias OutboundIn = ByteBuffer
	public typealias OutboundOut = ByteBuffer

	public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		// unwrap the incoming data to the declared InboundIn type
		let packet = unwrapInboundIn(data)

		// this is text data (JSON) so log it as a string
		if let packetString = packet.getString(at: 0, length: packet.readableBytes) {
			print("[INCOMING] \(packetString)")
		}

		// continue processing packet with next handler
		ctx.fireChannelRead(data)
	}

	public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
		// unwrap the outgoing data to the declared OutboundIn type
		let packet = unwrapOutboundIn(data)

		// this is text data (JSON) so log it as a string
		if let packetString = packet.getString(at: 0, length: packet.readableBytes) {
			print("[OUTGOING] \(packetString), promise=\(String(describing: promise))")
		}

		// continue writing the data down the outgoing pipeline
		ctx.write(data, promise: promise)
	}
}
