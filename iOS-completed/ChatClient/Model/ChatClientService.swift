import Foundation
import Network

typealias MessageReceivedCallback = (ServerMessage) -> Void
typealias ChatMessage = (user: String, text: String)

final class ChatClientService {

	// Network.framework needs a dedicated queue to operate on
	private let serverQueue = DispatchQueue(label: "chat-server-queue", qos: .background)

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
		self.serverEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(serverAddress), port: NWEndpoint.Port(rawValue: UInt16(serverPort))!)
	}

	func send(command: ClientCommand) {
		//sendFramed(command: command)
		sendUnframed(command: command)
	}

	private func sendUnframed(command: ClientCommand) {
		do {
			let jsonData = try JSONEncoder().encode(command)

			connection?.send(content: jsonData, completion: .contentProcessed({ error in
				if let error = error {
					print("Error sending message: \(error)")
				}
			}))
		}
		catch let err {
			print("Failed encoding JSON command: err=\(err)")
		}
	}

	private func sendFramed(command: ClientCommand) {
		do {
			let jsonData = try JSONEncoder().encode(command)

			var frameSize = NSSwapHostIntToBig(UInt32(jsonData.count))
			let headerData = Data(bytes: &frameSize, count: 4)
			connection?.send(content: headerData, isComplete: false, completion: .contentProcessed({ error in
				if let error = error {
					print("Error sending frame header: \(error)")
				}
			}))

			// send message over to the connection
			connection?.send(content: jsonData, completion: .contentProcessed({ error in
				if let error = error {
					print("Error sending frame contents: \(error)")
				}
			}))
		}
		catch let err {
			print("Failed encoding JSON command: err=\(err)")
		}
	}

	func connect() {
		self.connection = NWConnection(to: serverEndpoint, using: .tcp)
		guard let connection = self.connection  else {
			fatalError("Failed creating NWConnection")
		}
		setupConnectionStateHandler(connection)
		connection.start(queue: serverQueue)
		readNextMessage(connection)
	}

	func disconnect() {
		connection?.cancel()
	}

	private func setupConnectionStateHandler(_ connection: NWConnection) {
		connection.stateUpdateHandler = { (newState) in
			switch (newState) {
			case .setup:
				print("Connection setup")

			case .preparing:
				print("Connection preparing")

			case .ready:
				print("Connection established")
				self.send(command: .connect(username: self.username))

			case .waiting(let error):
				print("Connection to server waiting to establish, error=\(error)")
				self.serverQueue.asyncAfter(deadline: .now()+1) {
					self.connect()
				}

			case .failed(let error):
				print("Connection to server failed, error=\(error)")
				self.serverQueue.asyncAfter(deadline: .now()+1) {
					// retry after 1 second
					self.connect()
				}

			case .cancelled:
				print("Connection was cancelled, not retrying")
				break
			}
		}
	}

	private func readNextMessage(_ connection: NWConnection) {
		readNextUnframedMessage(connection)
	}

	private func readNextUnframedMessage(_ connection: NWConnection) {
		// Read a simple message from the connection. Note that this may turn to be unsafe
		// in case of packet fragmentation
		connection.receive(minimumIncompleteLength: 2, maximumLength: 256000) { (data: Data?, context: NWConnection.ContentContext?, complete: Bool, error: NWError?) in
			if let error = error {
				print("receiveMessage returned an error: \(error)")
				self.readNextMessage(connection)
				return
			}

			guard let data = data else {
				return
			}

			do {
				let message = try JSONDecoder().decode(ServerMessage.self, from: data)
				self.process(message: message)
				DispatchQueue.main.async {
					self.newMessageNotification?(message)
				}
			}
			catch let decodingErr {
				print("JSON decoding error: \(decodingErr)")
			}
			self.readNextMessage(connection)
		}
	}

	private func readNextFramedMessage(_ connection: NWConnection) {
		// Read message encoded on the server with `FramedMessageCodec`:
		// 4 bytes header giving the contents of the packed, followed by the packet data
		let headerSize = MemoryLayout<UInt32>.size
		connection.receive(minimumIncompleteLength: headerSize, maximumLength: headerSize) { (data: Data?, _, _, error: NWError?) in
			if let error = error {
				print("Error reading frame header: \(error)")
				self.readNextMessage(connection)
				return
			}

			guard let data = data else {
				return
			}

			var frameSize: UInt32 = 0
			_ = data.copyBytes(to: UnsafeMutableBufferPointer(start: &frameSize, count: MemoryLayout<UInt32>.size))
			frameSize = NSSwapBigIntToHost(frameSize)

			connection.receive(minimumIncompleteLength: Int(frameSize), maximumLength: Int(frameSize), completion: {  (data: Data?, _, _, error: NWError?) in
				if let error = error {
					print("Error reading frame contents: \(error)")
					self.readNextMessage(connection)
					return
				}

				guard let data = data else {
					return
				}

				do {
					let message = try JSONDecoder().decode(ServerMessage.self, from: data)
					self.process(message: message)
					DispatchQueue.main.async {
						self.newMessageNotification?(message)
					}
				}
				catch let decodingErr {
					print("JSON decoding error: \(decodingErr)")
				}
				self.readNextMessage(connection)
			})
		}
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
