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

public final class ServerChatRoomsHandler: ChannelInboundHandler, ChannelOutboundHandler {
	public typealias InboundIn = ClientCommand
	public typealias InboundOut = ClientCommand

	public typealias OutboundIn = Never
	public typealias OutboundOut = ServerMessage

	private let syncQueue = DispatchQueue(label: "syncQueue")

	private var online = Set<ChatUser>()
	private var rooms: [String]

	public init(rooms: [String]) {
		self.rooms = rooms
	}

	public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		let clientCommand = unwrapInboundIn(data)
		let channel = ctx.channel
		syncQueue.async {
			switch clientCommand {
				case .connect(let username):
					self.userConnected(name: username, channel: channel)
				case .disconnect:
					self.userDisconnected(channel)
				case .message(let room, let text):
					self.message(room: room, text: text, channel: channel)
				case .privateMessage(let username, let text):
					self.privateMessage(to: username, text: text, channel: channel)
			}
		}

		// since we implemented the method, we need to carry the callback
		// over to the next handler in the pipeline
		ctx.fireChannelRead(data)
	}

	public func channelInactive(ctx: ChannelHandlerContext) {
		// in case client didn't send is a `disconnect`, make sure we remove
		// user from the rooms it was in, and notify others
		let channel = ctx.channel
		syncQueue.async { self.userDisconnected(channel) }

		// since we implemented the method, we need to carry the callback
		// over to the next handler in the pipeline
		ctx.fireChannelInactive()
	}

	private func push(_ data: ServerMessage, to channel: Channel) {
		// send a ServerMessage to one user
		channel.writeAndFlush(wrapOutboundOut(data), promise: nil)
	}

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
