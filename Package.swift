// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "NovaNoise",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "NovaNoise", targets: ["NovaNoise"]),
        .library(name: "NovaNoiseUtils", targets: ["NovaNoiseUtils"])
    ],
    dependencies: [
        .package(name: "NovaCore", path: "../NovaCore/"),
    ],
    targets: [
        .target(name: "NovaNoise", dependencies: ["NovaCore"]),
        .target(name: "NovaNoiseUtils", dependencies: ["NovaCore", "NovaNoise"]),
        .testTarget(name: "NovaNoiseTests", dependencies: ["NovaNoise"]),
    ]
)
