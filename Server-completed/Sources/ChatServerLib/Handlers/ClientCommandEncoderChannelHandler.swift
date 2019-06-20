//
//  ClientCommandEncoderChannelHandler.swift
//  ChatServerTests
//
//  Created by Florent Pillet on 26/11/2018.
//

import Foundation
import NIO
import ChatCommon

public final class ClientCommandEncoderChannelHandler: MessageToByteEncoder {
	public typealias OutboundIn = ClientCommand
	public typealias OutboundOut = ByteBuffer

	public init() { }

	public func encode(data: ClientCommand, out: inout ByteBuffer) throws {
		do {
			let dataBytes = try JSONEncoder().encode(data)
			out.writeBytes(dataBytes)
		} catch let err {
			print("** Failed encoding ClientCommand to JSON. Err=\(err)\nMessage=\(data)")
		}
	}
}

