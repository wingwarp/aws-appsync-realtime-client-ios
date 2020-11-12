// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "build-support",
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.47.3"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.41.0")
    ],
    targets: [
        .target(name: "build-support", path: "")
    ]
)
