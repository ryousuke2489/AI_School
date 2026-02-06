// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CodexBar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CodexBarCore",
            targets: ["CodexBarCore"]
        ),
        .executable(
            name: "CodexBar",
            targets: ["CodexBar"]
        ),
        .executable(
            name: "codexbar-cli",
            targets: ["CodexBarCLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "CodexBarCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .executableTarget(
            name: "CodexBar",
            dependencies: [
                "CodexBarCore",
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .executableTarget(
            name: "CodexBarCLI",
            dependencies: [
                "CodexBarCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "CodexBarTests",
            dependencies: ["CodexBarCore"]
        ),
    ]
)
