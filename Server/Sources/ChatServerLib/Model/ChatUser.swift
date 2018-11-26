import Foundation
import NIO

public struct ChatUser {
	let name: String
	let channel: Channel
	let uniqueIdentifier: ObjectIdentifier
}

extension ChatUser: Equatable {
	public static func ==(lhs: ChatUser, rhs: ChatUser) -> Bool {
		return lhs.uniqueIdentifier == rhs.uniqueIdentifier
	}
}

extension ChatUser: Comparable {
	// This is mainly to sort users in user lists
	public static func < (lhs: ChatUser, rhs: ChatUser) -> Bool {
		return lhs.name.localizedCompare(rhs.name) == .orderedAscending
	}
}

extension ChatUser: Hashable {
	public func hash(into hasher: inout Hasher) {
		uniqueIdentifier.hash(into: &hasher)
	}
}
