import UIKit
import MessengerKit

struct User: MSGUser {
	var displayName: String
	var avatar: UIImage?
	var isSender: Bool
}

typealias SendMessageCallback = (MessageBoard, String) -> Void

class MessagesViewController: MSGMessengerViewController {

	var sendMessageCallback: SendMessageCallback = { (_,_) in }

	// users in the room
	private var myself: User?
	private var others: [User] = []

	// this holds all the messages to display
	private var messages = [[MSGMessage]]()
	private var nextMessageID = 1

	// we are either in a room, or in private talk with another user
	private var board: MessageBoard? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		dataSource = self
		messageInputView.addTarget(self, action: #selector(sendMessage), for: .primaryActionTriggered)
	}

	@objc func sendMessage() {
		guard let board = board else { return }
		sendMessageCallback(board, messageInputView.message)
	}

	func configure(myName: String, board: MessageBoard, boardContents: [ChatMessage], sendMessage: @escaping SendMessageCallback) {
		self.sendMessageCallback = sendMessage
		self.board = board
		self.messages = []
		self.myself = User(displayName: myName, avatar: nil, isSender: true)
		for message in boardContents {
			appendMessage(.text(message.text), from: message.user)
		}
		self.collectionView.reloadData()
		switch board {
		case .room(let roomName):
			self.title = "Group chat in #\(roomName)"
		case .user(let userName):
			self.title = "Private chat with @\(userName)"
		}
	}

	func processServerMessage(_ serverMessage: ServerMessage) {
		guard let board = board else { return }
		switch serverMessage {
		case .connected, .disconnected, .rooms, .users:
			// chat display is not interested in these ones
			break

		case .message(let inRoom, let username, let text):
			if case .room(let room) = board, room == inRoom {
				appendMessage(.text(text), from: username)
				collectionView.reloadData()
			}

		case .privateMessage(let from, let to, let text):
			if case .user(let withUser) = board, withUser == from || withUser == to {
				appendMessage(.text(text), from: from)
				collectionView.reloadData()
			}
		}
	}
}

extension MessagesViewController {
	private func appendMessage(_ messageBody: MSGMessageBody, from: String) {
		let id = self.nextMessageID
		self.nextMessageID += 1
		let user: User
		if let myself = myself, myself.displayName == from {
			user = myself
		} else {
			if let existing = others.first(where: { $0.displayName == from }) {
				user = existing
			} else {
				user = User(displayName: from, avatar: nil, isSender: false)
				others.append(user)
			}
		}
		let message = MSGMessage(id: id, body: messageBody, user: user, sentAt: Date())

		if var lastGroup = messages.last, let lastMessage = lastGroup.last, lastMessage.user.displayName == from {
			lastGroup.append(message)
			messages[messages.count-1] = lastGroup
		} else {
			messages.append([message])
		}
	}

}

extension MessagesViewController: MSGDataSource {
	func numberOfSections() -> Int {
		return messages.count
	}

	func numberOfMessages(in section: Int) -> Int {
		return messages[section].count
	}

	func message(for indexPath: IndexPath) -> MSGMessage {
		return messages[indexPath.section][indexPath.item]
	}

	func footerTitle(for section: Int) -> String? {
		return ""
	}

	func headerTitle(for section: Int) -> String? {
		return messages[section].first?.user.displayName
	}
}
