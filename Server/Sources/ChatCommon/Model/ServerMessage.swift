import Foundation

public enum ServerMessage: Equatable {
	case connected(to: String)
	case disconnected
	case rooms([String])
	case users([String])
	case message(room: String, username: String, text: String)
	case privateMessage(from: String, to: String, text: String)
}
