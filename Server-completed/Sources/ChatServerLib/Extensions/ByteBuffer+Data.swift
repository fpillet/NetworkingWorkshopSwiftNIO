//
// Created by Florent Pillet on 2018-11-21.
//

import Foundation
import NIO

extension ByteBuffer {
	public mutating func write(_ data: Data) {
		writeWithUnsafeMutableBytes { (bufferMutablePointer: UnsafeMutableRawBufferPointer) -> Int in
			data.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> Void in
				bufferMutablePointer.copyMemory(from: UnsafeRawBufferPointer(start: UnsafeRawPointer(pointer), count: data.count))
			}
			return data.count
		}
	}
}
