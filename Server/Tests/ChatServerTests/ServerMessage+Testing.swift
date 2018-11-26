
import Foundation
import ChatCommon

extension ServerMessage {
	var isConnected: Bool {
		if case .connected = self { return true }
		return false
	}

	var isDisconnected: Bool {
		if case .disconnected = self { return true }
		return false
	}

	func isRoomsList(_ rooms: String...) -> Bool {
		if case .rooms(let names) = self {
			return Set(rooms) == Set(names)
		}
		return false
	}

	func isUsersList(_ users: String...) -> Bool {
		if case .users(let names) = self {
			return Set(users) == Set(names)
		}
		return false
	}
}
