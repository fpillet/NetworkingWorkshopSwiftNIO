import Foundation

// A "message board" is either a chat root or a direct discussion with another user
enum MessageBoard {
	case room(String)
	case user(String)

	var displayName: String {
		switch self {
		case .room(let name), .user(let name):
			return name
		}
	}

	var isRoom: Bool {
		if case .room = self {
			return true
		}
		return false
	}
}

extension MessageBoard: Equatable {
	public static func ==(lhs: MessageBoard, rhs: MessageBoard) -> Bool {
		switch (lhs, rhs) {
			case (.room(let left), .room(let right)), (.user(let left), .user(let right)):
				return left == right
			default:
				return false
		}
	}
}

extension MessageBoard: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
			case .room(let roomName): roomName.hash(into: &hasher)
			case .user(let userName): userName.hash(into: &hasher)
		}
	}
}

extension Collection where Element == MessageBoard {
	func sortedByDisplayName() -> [MessageBoard] {
		return self.sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
	}
}
