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
		
		// 1. Setup the `serverEndpoint` that contains the host & port of the server
		// TODO: self.serverEndpoint = NWEndpoint.hostPort(...)
		
		self.serverEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(serverAddress), port: NWEndpoint.Port(rawValue: UInt16(serverPort))!)
	}

	func connect() {
		// 1. Create a NWConnection to the serverEndpoint. Hint: we need to use a TCP connection,
		// so look for the default tcp NWParameters
		
		// TODO: self.connection = NWConnection(...)
		
		self.connection = NWConnection(to: serverEndpoint, using: .tcp)

		// we should obtain a non-nil connection object
		guard let connection = self.connection  else {
			fatalError("Failed creating NWConnection")
		}

		// 2. Setup our connection state handler that will manage transitions in the connection state
		setupConnectionStateHandler(connection)

		// 3. Open the connection. This tells Network.Framework to effectively connect to the server
		
		// TODO: connection.start(...)
		connection.start(queue: serverQueue)
		
		// 4. Start reading messages from the server. We need to read a first message then
		// our readNextMessage function will chain the next reads
		
		// TODO: readNextMessage(connection)
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
				// 1. once the connection is established, we need to tell the server who we are
				// TODO: self.send(command: .connect(username: self.username))
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
	
	func send(command: ClientCommand) {
		// Send a command to the server. It contains two parts:
		//
		// - a 4-byte header (encoded in big endian) that gives the size of the rest of the message
		// - the actual JSON data itself
		//

		do {
			// 1. encode our command to JSON using Codable
			let jsonData = try JSONEncoder().encode(command)

			// 2. now that we have data, we need to know its size and prepare the frame header
			let headerData = encodeFrameHeader(size: jsonData.count)

			// 3. send the header data over to the server. Note that we need to tell Network.framework
			// that our message is NOT COMPLETE yet, because we send the header and the data separately
			
			// TODO: connection?.send(...) for headerData
			
			connection?.send(content: headerData, isComplete: false, completion: .contentProcessed({ error in
				if let error = error {
					print("Error sending frame header: \(error)")
				}
			}))
			
			// 4. send the actual message data. Note that the send callback is just here to indicate whether there was an error

			// TODO: connection?.send(...) for jsonData

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
	
	private func readNextMessage(_ connection: NWConnection) {
		// Read message encoded by the server. It contains two parts:
		//
		// - a 4-byte header (encoded in big endian) that gives the size of the rest of the message
		// - the actual JSON data itself
		//

		let headerSize = MemoryLayout<UInt32>.size
		
		// 1. Issue a first `connection.receive` to read EXACTLY `headerSize` bytes to get the frame header
		// TODO: connnection.receive(...) {

		connection.receive(minimumIncompleteLength: headerSize, maximumLength: headerSize) { (data: Data?, _, _, error: NWError?) in

			// 2. inside the connection.receive callback, check if we got an error.
			// TODO: if we got an error, print it out and close the connection. Our state handler will try to reopen the connection.

			if let error = error {
				print("Error reading frame header: \(error)")
				connection.cancel()
				return
			}

			// 3. if we got non-nil data, use the 4 bytes to know how much we need to read next
			// TODO: if let headerData = data {
			// TODO:	let frameSize = self.decodeFrameHeader(data: headerData)
			
			if let headerData = data {
				let frameSize = self.decodeFrameHeader(data: headerData)

				// 4. Now that we know how many bytes the frame contains, we can issue a `connection.receive` for the rest of the frame
				// TODO: `connection.receive(...) {

				connection.receive(minimumIncompleteLength: frameSize, maximumLength: frameSize, completion: {  (data: Data?, _, _, error: NWError?) in
					
					// 5. inside the connection.receive callback, check if we got an error.
					// TODO: if we got an error, print it out and close the connection. Our state handler will try to reopen the connection.

					if let error = error {
						print("Error reading frame contents: \(error)")
						connection.cancel()
						return
					}
					
					// 6. if data is not nil, we now have a message that we can process
					// TODO: self.processFrameContents(data: ...)
					
					if let messageContents = data {
						self.processFrameContents(data: messageContents)
					}
					
					// 7. VERY IMPORTANT: we must initiate the read for the next message, or we will never get another message from the server
					// TODO: self.readNextMessage(connection)

					self.readNextMessage(connection)
				})
			} else {
				// in the improbable case where data is nil, we still want to
				// keep reading from the connection
				self.readNextMessage(connection)
			}
		}
	}
	
	private func encodeFrameHeader(size: Int)  -> Data {
		// encode the frame header to 4 bytes big endian
		var frameSize = UInt32(size).bigEndian
		return Data(bytes: &frameSize, count: 4)
	}

	private func decodeFrameHeader(data: Data) -> Int {
		// decodes the 4 bytes frame header (sent as big endian on the wire) to an Int
		var frameSize: UInt32 = 0
		_ = data.copyBytes(to: UnsafeMutableBufferPointer(start: &frameSize, count: MemoryLayout<UInt32>.size))
		frameSize = NSSwapBigIntToHost(frameSize)
		return Int(frameSize)
	}

	private func processFrameContents(data: Data) {
		// once we have the actual data for a frame, decode the JSON to a ServerMessage
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
