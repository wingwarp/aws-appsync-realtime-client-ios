// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AppSyncRealTimeClient",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "AppSyncRealTimeClient",
            targets: ["AppSyncRealTimeClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream", .upToNextMinor(from: "3.1.1"))
    ],
    targets: [
        .target(
            name: "AppSyncRealTimeClient",
            dependencies: ["Starscream"],
            path: "AppSyncRealTimeClient"
        ),
        .testTarget(
            name: "AppSyncRealTimeClientTests",
            dependencies: ["AppSyncRealTimeClient"],
            path: "AppSyncRealTimeClientTests"
        )
    ]
)
