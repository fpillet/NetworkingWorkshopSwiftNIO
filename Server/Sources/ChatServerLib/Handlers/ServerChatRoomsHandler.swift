//
//  ChatRoomsHandler.swift
//  server
//
//  Created by Florent Pillet on 20/11/2018.
//

import Foundation
import NIO
import ChatCommon

// The main functionality of this server

// TODO: make it a handle for IN and OUT data

public final class ServerChatRoomsHandler {

	// TODO: define the IN and OUT types

	// storage for our helper functions
	private var online = Set<ChatUser>()
	private var rooms: [String]

	public init(rooms: [String]) {
		self.rooms = rooms
	}

	// TODO: receive and process ClientCommand from clients

	// TODO: handle the case of a disconnected client to update the list of online users

	/*
 	 * Helper functions -- Use them to speed up your development!
 	 *
	 */
	private func onlineUser(_ channel: Channel) -> ChatUser? {
		let uniqueIdentifier = ObjectIdentifier(channel)
		return online.first { $0.uniqueIdentifier == uniqueIdentifier }
	}

	private func userConnected(name: String, channel: Channel) {
		// TODO: upon connection, user should receivce the list of rooms and the list of connected users
	}

	private func userDisconnected(_ channel: Channel) {
		// TODO: update the list of connected users for all remaining users
	}

	private func listRooms(_ channel: Channel) {
		// TODO: send the list of rooms to one user
	}

	private func listUsers(_ channel: Channel) {
		// TODO: send the list of connected users to one user
	}

	private func message(room: String, text: String, channel: Channel) {
		// TODO: send a message from a user in a public room to all connected users
	}

	private func privateMessage(to: String, text: String, channel: Channel) {
		// TODO: send a private message from one connected user to another
	}
}
