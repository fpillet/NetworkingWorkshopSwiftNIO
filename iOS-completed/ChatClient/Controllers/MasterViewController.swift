//
//  MasterViewController.swift
//  ChatClient
//
//  Created by Florent Pillet on 22/11/2018.
//  Copyright © 2018 SwiftAlps. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

	var detailViewController: MessagesViewController? = nil

	let chatService = ChatClientService(username: Constants.username, serverAddress: Constants.serverAddress, serverPort: Constants.serverPort)

	// stuff we need to update the display
	private var rooms = [MessageBoard]()
	private var users = [MessageBoard]()

	private func sendMessage(_ board: MessageBoard, _ message: String) {
		chatService.sendMessage(board: board, message: message)
	}

	private func processMessage(_ message: ServerMessage) {
		switch message {
		case .rooms, .users:
			updateRoomsAndUsers()

		default:
			break
		}
		DispatchQueue.main.async {
			self.messagesViewController()?.processServerMessage(message)
		}
	}

	private func updateRoomsAndUsers() {
		self.rooms = self.chatService.messageBoards.keys.filter { $0.isRoom }.sortedByDisplayName()
		self.users = self.chatService.messageBoards.keys.filter { !$0.isRoom }.sortedByDisplayName()
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}

	private func messagesViewController() -> MessagesViewController? {
		return (splitViewController?.viewControllers.last as? UINavigationController)?.topViewController as? MessagesViewController
	}

	// MARK: - Basic ViewController stuff
	
	override func viewDidLoad() {
		super.viewDidLoad()
		messagesViewController()?.view.isHidden = true

		// in real life, avoid doing this as you're introducing a retain cycle
		chatService.newMessageNotification = self.processMessage
		chatService.connect()
	}

	override func viewWillAppear(_ animated: Bool) {
		clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
		super.viewWillAppear(animated)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDetail" {
			if let indexPath = tableView.indexPathForSelectedRow {
				let controller = (segue.destination as! UINavigationController).topViewController as! MessagesViewController
				controller.view.isHidden = false
				controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
				controller.navigationItem.leftItemsSupplementBackButton = true

				let board = (indexPath.section == 0) ? rooms[indexPath.row] : users[indexPath.row]

				controller.configure(myName: chatService.username,
									 board: board,
									 boardContents: chatService.messageBoards[board] ?? [],
									 sendMessage: self.sendMessage)
			} else {
				let controller = (segue.destination as! UINavigationController).topViewController
				controller?.view.isHidden = true
			}
		}
	}

	// MARK: - Table View

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? rooms.count : users.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		if indexPath.section == 0 {
			let name = rooms[indexPath.row].displayName
			cell.textLabel!.text = "#\(name)"
		} else {
			let name = users[indexPath.row].displayName
			cell.textLabel!.text = "@\(name)"
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let label = UILabel()
		label.text = (section == 0) ? " Rooms" : " Users"
		label.textColor = UIColor.darkGray
		return label
	}

	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 40.0
	}
}

