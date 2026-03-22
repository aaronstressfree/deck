// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Deck",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "Deck",
            dependencies: ["SwiftTerm"],
            path: "Sources/Deck",
            resources: [
                .copy("Resources/claude-icon.png"),
                .copy("Resources/claude-icon@2x.png"),
                .copy("Resources/AppIcon.icns"),
            ]
        ),
        .testTarget(
            name: "DeckTests",
            dependencies: ["Deck"],
            path: "Tests/DeckTests"
        ),
    ]
)
