// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "build-support",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.47.3"),
        .package(url: "https://github.com/realm/SwiftLint.git", from: "0.41.0")
    ],
    targets: [
        .target(
          name: "build-support",
          path: "",
          exclude: ["setup_private_specs.sh"]
        )
    ]
)
