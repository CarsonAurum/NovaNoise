// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "NovaNoise",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "NovaNoise", targets: ["NovaNoise"])
    ],
    dependencies: [
        .package(name: "NovaCore", path: "../NovaCore/"),
    ],
    targets: [
        .target(name: "NovaNoise", dependencies: ["NovaCore"], path: "Sources/"),
        .testTarget(name: "NovaNoiseTests", dependencies: ["NovaNoise"]),
    ]
)
