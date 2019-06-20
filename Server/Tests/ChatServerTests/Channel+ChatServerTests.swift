//
//  Channel+ChatServerTests.swift
//  ChatServerTests
//
//  Created by Florent Pillet on 26/11/2018.
//

import Foundation
import NIO
import ChatCommon

extension Channel {
	func writeAndFlush(_ string: String) -> EventLoopPromise<Void> {
		let promise: EventLoopPromise<Void> = self.eventLoop.makePromise()
		var buffer = self.allocator.buffer(capacity: string.utf8.count)
		buffer.writeString(string)
		self.writeAndFlush(buffer, promise: promise)
		return promise
	}

	func writeAndFlush(_ data: Data) -> EventLoopPromise<Void> {
		let promise: EventLoopPromise<Void> = self.eventLoop.makePromise()
		var buffer = self.allocator.buffer(capacity: data.count)
		buffer.writeBytes(data)
		self.writeAndFlush(buffer, promise: promise)
		return promise
	}

	func send(_ command: ClientCommand) throws -> EventLoopFuture<Void> {
		return writeAndFlush(try JSONEncoder().encode(command)).futureResult
	}
}
