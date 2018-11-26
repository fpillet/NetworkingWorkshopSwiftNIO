import Foundation

enum ChatEntry {
	case message(ChatMessage)
	case userJoined(String)
	case userLeft(String)
}
