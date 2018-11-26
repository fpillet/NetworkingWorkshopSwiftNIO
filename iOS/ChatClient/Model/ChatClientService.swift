import Foundation
import Network

typealias MessageReceivedCallback = (ServerMessage) -> Void
typealias ChatMessage = (user: String, text: String)

final class ChatClientService {

	// This is the connection we operate on, once established
	private var connection: NWConnection? = nil
	let serverEndpoint: NWEndpoint

	// Some internal stuff for us
	let username: String

	// Some state we keep
	private(set) var loggedIn = false
	private(set) var messageBoards = [MessageBoard:[ChatMessage]]()

	// Configurable notification callback that fires when we receive a message from the server
	var newMessageNotification: MessageReceivedCallback? = nil

	init(username: String, serverAddress: String, serverPort: Int) {
		self.username = username
		// TODO: prepare the endpoint that will connect to the server
	}

	func send(command: ClientCommand) {
		sendFramed(command: command)
	}

	private func sendUnframed(command: ClientCommand) {
		// TODO: send an unframed JSON packet to the server
	}

	private func sendFramed(command: ClientCommand) {
		// TODO: send a framed JSON packet to the server
	}

	func connect() {
		// TODO: setup the connection to the server

		setupConnectionStateHandler(connection)

		// TODO: start the connection and start listening to server messages
	}

	func disconnect() {
		connection?.cancel()
	}

	private func setupConnectionStateHandler(_ connection: NWConnection) {
	}

	private func readNextMessage(_ connection: NWConnection) {
		readNextFramedMessage(connection)
	}

	private func readNextUnframedMessage(_ connection: NWConnection) {
		// TODO: Read a simple message from the connection. Note that this may turn to be unsafe
		// in case of packet fragmentation
	}

	private func readNextFramedMessage(_ connection: NWConnection) {
		// TODO: Read message encoded on the server with `FramedMessageCodec`:
		// 4 bytes header giving the contents of the packed, followed by the packet data
	}

	func sendMessage(board: MessageBoard, message: String) {
		switch board {
			case .room(let room):
				send(command: .message(room: room, text: message))

			case .user(let toUser):
				send(command: .privateMessage(username: toUser, text: message))
		}
	}

	private func process(message: ServerMessage) {
		print("Processing server message: \(message)")
		switch message {

		case .connected:
			loggedIn = true

		case .disconnected:
			loggedIn = false

		case .rooms(let roomNames):
			roomNames.forEach {
				let board = MessageBoard.room($0)
				if self.messageBoards[board] == nil {
					self.messageBoards[board] = []
				}
			}

		case .users(let users):
			users.forEach {
				let board = MessageBoard.user($0)
				if self.messageBoards[board] == nil {
					self.messageBoards[board] = []
				}
			}

		case .message(let room, let username, let text):
			let board = MessageBoard.room(room)
			var entries = messageBoards[board] ?? []
			entries.append(ChatMessage(user: username, text: text))
			messageBoards[board] = entries

		case .privateMessage(let from, let to, let text):
			let party = from == username ? to : from
			let board = MessageBoard.user(party)
			var entries = messageBoards[board] ?? []
			entries.append(ChatMessage(user: from, text: text))
			messageBoards[board] = entries
		}
	}
}
