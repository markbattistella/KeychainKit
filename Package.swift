// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "KeychainKit",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .visionOS(.v1),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "KeychainKit",
            targets: ["KeychainKit"]
        )
    ],
    targets: [
        .target(
            name: "KeychainKit",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]

        )
    ]
)
