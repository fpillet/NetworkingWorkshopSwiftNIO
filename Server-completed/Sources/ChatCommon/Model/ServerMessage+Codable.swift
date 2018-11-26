import Foundation

extension ServerMessage: Codable {
	private enum CodingKeys: String, CodingKey {
		case command
		case data
	}

	private enum Cmd: String, Codable {
		case connected, disconnected, rooms, users, message, privateMessage
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Cmd.self, forKey: .command) {
			case .connected:
				let server = try container.decode(String.self, forKey: .data)
				self = .connected(to: server)
			case .disconnected:
				self = .disconnected
			case .rooms:
				let rooms = try container.decode([String].self, forKey: .data)
				self = .rooms(rooms)
			case .users:
				let users = try container.decode([String].self, forKey: .data)
				self = .users(users)
			case .message:
				let data = try container.decode(MessageData.self, forKey: .data)
				self = .message(room: data.to, username: data.from, text: data.text)
			case .privateMessage:
				let data = try container.decode(MessageData.self, forKey: .data)
				self = .privateMessage(from: data.from, to: data.to, text: data.text)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
			case .connected(let to):
				try container.encode(Cmd.connected, forKey: .command)
				try container.encode(to, forKey: .data)
			case .disconnected:
				try container.encode(Cmd.disconnected, forKey: .command)
			case .rooms(let rooms):
				try container.encode(Cmd.rooms, forKey: .command)
				try container.encode(rooms, forKey: .data)
			case .users(let users):
				try container.encode(Cmd.users, forKey: .command)
				try container.encode(users, forKey: .data)
			case .message(let room, let username, let text):
				try container.encode(Cmd.message, forKey: .command)
				try container.encode(MessageData(from: username, to: room, text: text), forKey: .data)
			case .privateMessage(let from, let to, let text):
				try container.encode(Cmd.privateMessage, forKey: .command)
				try container.encode(MessageData(from: from, to: to, text: text), forKey: .data)
		}
	}
}

// Pieces of data we need to encode / decode JSON

private struct RoomAndUsername: Codable {
	let room: String
	let username: String
}

private struct MessageData: Codable {
	let from: String
	let to: String
	let text: String
}
