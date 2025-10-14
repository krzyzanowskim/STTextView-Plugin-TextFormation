// swift-tools-version: 5.8

import PackageDescription

let settings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "TextFormationPlugin",
    platforms: [.macOS(.v12), .iOS(.v16), .macCatalyst(.v16)],
    products: [
        .library(name: "TextFormationPlugin", targets: ["TextFormationPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/STTextView", from: "2.2.1"),
        .package(url: "https://github.com/ChimeHQ/TextFormation", from: "0.9.0"),
        .package(url: "https://github.com/ChimeHQ/TextStory", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "TextFormationPlugin",
            dependencies: [
                .product(name: "STTextView", package: "STTextView"),
                "TextStory",
                "TextFormation",
            ],
            swiftSettings: settings
        ),
        .testTarget(
            name: "TextFormationPluginTests",
            dependencies: ["TextFormationPlugin"],
            swiftSettings: settings
        ),
    ]
)
