import Foundation

public class ChatRoom {
	public var rooms = [String:[ChatUser]]()

	public func users(room: String) -> [ChatUser] {
		return rooms[room] ?? []
	}
}
