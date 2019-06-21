import Foundation
import NIO
import ChatCommon

// Receives a ByteBuffer and outputs a ClientCommand

public final class ClientCommandDecoderChannelHandler: ChannelInboundHandler {
	// the types of data that we receive and emit
	
	//	TODO: public typealias InboundIn = ByteBuffer
	//	TODO: public typealias InboundOut = ClientCommand

	public init() { }

	// TODO: implement channelRead and decode the incoming ByteBuffer from JSON to ClientCommand
}
