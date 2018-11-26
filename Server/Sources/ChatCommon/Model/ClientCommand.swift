import Foundation

public enum ClientCommand: Equatable {
	case connect(username: String)
	case disconnect
	case message(room: String, text: String)
	case privateMessage(username: String, text: String)
}
