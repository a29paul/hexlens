// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacLeagueOverlay",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MacLeagueOverlay",
            dependencies: ["Starscream"],
            path: "Sources"
        ),
        .testTarget(
            name: "MacLeagueOverlayTests",
            dependencies: [],
            path: "Tests"
        ),
    ]
)
