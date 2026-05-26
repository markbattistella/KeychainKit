// swift-tools-version: 6.0

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
        .swiftLanguageMode(.v6)
      ]
    ),
    .testTarget(
      name: "KeychainKitTests",
      dependencies: ["KeychainKit"],
      swiftSettings: [
        .swiftLanguageMode(.v6)
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
