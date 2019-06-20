// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ChatServer",
	products: [
		.library(name: "ChatCommon", targets: ["ChatCommon"]),
		.library(name: "ChatServerLib", targets: ["ChatServerLib"]),
		.executable(name: "ChatServer", targets: ["ChatServer"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.2.0"),
	],
	targets: [
		.target(name: "ChatCommon", dependencies: ["NIO"]),
		.target(name: "ChatServerLib", dependencies: ["NIO","ChatCommon"]),
		.target(name: "ChatServer", dependencies: ["ChatServerLib"]),
		.testTarget(name: "ChatServerTests", dependencies: ["ChatServerLib"])
	]
)
