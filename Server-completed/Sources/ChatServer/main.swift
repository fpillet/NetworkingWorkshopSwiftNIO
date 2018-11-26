import ChatServerLib

guard let server = startServer(rooms: ["Red Team","Blue Team","General","Random"]) else {
	fatalError("Failed starting server")
}

// this will never exit
try! server.1.closeFuture.wait()

print("Done.")


