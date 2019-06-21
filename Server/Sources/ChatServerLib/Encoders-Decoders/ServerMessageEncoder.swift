//
// Created by Florent Pillet on 2018-11-21.
//

import Foundation
import NIO
import ChatCommon

public final class ServerMessageEncoder: MessageToByteEncoder {
	public typealias OutboundIn = ServerMessage
	public typealias OutboundOut = ByteBuffer

	public init() { }

	public func encode(data: ServerMessage, out: inout ByteBuffer) throws {
		do {
			let dataBytes = try JSONEncoder().encode(data)
			out.writeBytes(dataBytes)
		} catch let err {
			print("** Failed encoding ServerMessage to JSON. Err=\(err)\nMessage=\(data)")
		}
	}
}
