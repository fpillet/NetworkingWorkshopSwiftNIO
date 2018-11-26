import Foundation

extension ClientCommand: Codable {
	private enum CodingKeys: String, CodingKey {
		case command
		case data
	}

	private enum Cmd: String, Codable {
		case connect, disconnect, message, privateMessage
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Cmd.self, forKey: .command) {
		case .connect:
			let username = try container.decode(String.self, forKey: .data)
			self = .connect(username: username)
		case .disconnect:
			self = .disconnect
		case .message:
			let msg = try container.decode(MessageData.self, forKey: .data)
			self = .message(room: msg.to, text: msg.text)
		case .privateMessage:
			let msg = try container.decode(MessageData.self, forKey: .data)
			self = .privateMessage(username: msg.to, text: msg.text)
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .connect(let username):
			try container.encode(Cmd.connect, forKey: .command)
			try container.encode(username, forKey: .data)
		case .disconnect:
			try container.encode(Cmd.disconnect, forKey: .command)
		case .message(let room, let text):
			try container.encode(Cmd.message, forKey: .command)
			try container.encode(MessageData(to: room, text: text), forKey: .data)
		case .privateMessage(let username, let text):
			try container.encode(Cmd.privateMessage, forKey: .command)
			try container.encode(MessageData(to: username, text: text), forKey: .data)
		}
	}
}

private struct MessageData: Codable {
	let to: String
	let text: String
}
