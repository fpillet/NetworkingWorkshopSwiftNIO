import XCTest
import NIO
import ChatCommon
import ChatServerLib

let testPort = 9998

final class ChatServerTests: XCTestCase {

	var server: (MultiThreadedEventLoopGroup, Channel)!

	override func setUp() {
		server = setupChatServer(rooms: ["room1","room2"])
	}

	override func tearDown() {
		tearDownServer(server)
	}

	private func newChatClient(_ name: String) throws -> ChatClient {
		let client = try ChatClient.connect(host: "::1", port: testPort, group: server.0).wait()
		try client.send(.connect(username: name)).wait()
		return client
	}

	func testConnect() throws {
		let client = try newChatClient("Jim")
		let result = try client.expect(2).wait()

		XCTAssertTrue(result.contains(.rooms(["room1","room2"])))
		XCTAssertTrue(result.contains(.users(["Jim"])))
	}

	func testConnectTwoClients() throws {
		let _ = try newChatClient("Jim")
		let client2 = try newChatClient("John")

		let result2 = try client2.expect(2).wait()
		XCTAssertTrue(result2.contains(.rooms(["room1","room2"])))
		XCTAssertTrue(result2.contains { $0.isUsersList("Jim","John") })
	}

	func testMessageInRoom() throws {
		let client = try newChatClient("Jim")
		try client.skip(2).wait()

		try client.send(.message(room: "room1", text: "Hello, world")).wait()

		let broadcast = try client.expect(1).wait()
		XCTAssertEqual(broadcast, [.message(room: "room1", username: "Jim", text: "Hello, world")])
	}

	func testMessageInRoomBroadcast() throws {
		let jim = try newChatClient("Jim")
		let _ = try jim.expect(2).wait()

		let john = try newChatClient("John")
		let _ = try john.expect(2).wait()		// rooms + users

		let update = try jim.expect(1).wait()		// updated users list
		XCTAssertTrue(update[0].isUsersList("Jim","John"))

		try john.send(.message(room: "room1", text: "Hello, world")).wait()

		let broadcast1 = try jim.expect(1).wait()
		XCTAssertEqual(broadcast1, [.message(room: "room1", username: "John", text: "Hello, world")])

		let broadcast2 = try john.expect(1).wait()
		XCTAssertEqual(broadcast2, [.message(room: "room1", username: "John", text: "Hello, world")])
	}

	func testPrivateMessage() throws {
		let jim = try newChatClient("Jim")
		try jim.skip(2).wait()

		let john = try newChatClient("John")
		try john.skip(2).wait()
		try jim.skip(1).wait()

		try jim.send(.privateMessage(username: "John", text: "Hello John")).wait()

		let jimReceived = try jim.expect(1).wait()
		XCTAssertEqual(jimReceived, [.privateMessage(from: "Jim", to: "John", text: "Hello John")])

		let johnReceived = try john.expect(1).wait()
		XCTAssertEqual(johnReceived, [.privateMessage(from: "Jim", to: "John", text: "Hello John")])
	}

	func testDisconnectUpdate() throws {
		let jim = try newChatClient("Jim")
		try jim.skip(2).wait()
		
		let john = try newChatClient("John")
		try john.skip(2).wait()
		try jim.skip(1).wait()

		try jim.send(.disconnect).wait()
		
		let johnReceived = try john.expect(1).wait()
		XCTAssertEqual(johnReceived, [.users(["John"])])
	}

	func testDisconnectWithoutClientNotifying() throws {
		let jim = try newChatClient("Jim")
		try jim.skip(2).wait()
		let john = try newChatClient("John")
		try john.skip(2).wait()
		try jim.skip(1).wait()

		try jim.close()

		let johnReceived = try john.expect(1).wait()
		XCTAssertEqual(johnReceived, [.users(["John"])])
	}
}
