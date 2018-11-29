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

// TODO: make it a handler for IN and OUT data

public final class ServerChatRoomsHandler: ChannelInboundHandler, ChannelOutboundHandler {

	public typealias InboundIn = ClientCommand
	public typealias OutboundIn = ServerMessage

	// storage for our helper functions
	private var online = Set<ChatUser>()
	private var rooms: [String]

	public init(rooms: [String]) {
		self.rooms = rooms
	}

	// TODO: receive and process ClientCommand from clients

	// TODO: handle the case of a disconnected client to update the list of online users

	/*
	* Helper functions
	*
	*/

	private func onlineUser(_ channel: Channel) -> ChatUser? {
		let uniqueIdentifier = ObjectIdentifier(channel)
		return online.first { $0.uniqueIdentifier == uniqueIdentifier }
	}

	private func userConnected(name: String, channel: Channel) {
		let uniqueIdentifier = ObjectIdentifier(channel)
		online.insert(ChatUser(name: name, channel: channel, uniqueIdentifier: uniqueIdentifier))
		listRooms(channel)
		for user in online {
			listUsers(user.channel)
		}
	}

	private func userDisconnected(_ channel: Channel) {
		if let user = onlineUser(channel) {
			online.remove(user)
			for user in online {
				listUsers(user.channel)
			}
		}
	}

	private func listRooms(_ channel: Channel) {
		push(ServerMessage.rooms(rooms.sorted()), to: channel)
	}

	private func listUsers(_ channel: Channel) {
		let users = online.map { $0.name }
		push(ServerMessage.users(users.sorted()), to: channel)
	}

	private func message(room: String, text: String, channel: Channel) {
		guard let user = onlineUser(channel) else {
			return
		}
		let msg = ServerMessage.message(room: room, username: user.name, text: text)
		online.forEach { user in self.push(msg, to: user.channel) }
	}

	private func privateMessage(to: String, text: String, channel: Channel) {
		guard let fromUser = onlineUser(channel),
			let toUser = online.first(where: { $0.name == to }) else {
				return
		}
		let message = ServerMessage.privateMessage(from: fromUser.name, to: toUser.name, text: text)
		push(message, to: toUser.channel)
		push(message, to: fromUser.channel)
	}
}
