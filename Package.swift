// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-static",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "demo-site",
            targets: ["DemoSite"],
        ),
        .library(
            name: "swift-static",
            targets: ["SwiftStatic"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.27.1")),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3"),
        .package(url: "https://github.com/jectivex/JXKit.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "DemoSite",
            dependencies: [
                "SwiftStatic"
            ],
        ),
        .target(
            name: "SwiftStatic",
            dependencies: [
                "HLJS",
                .product(name: "FlyingFox", package: "FlyingFox"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Yams", package: "Yams"),
            ],
        ),
        .target(
            name: "HLJS",
            dependencies: [
                .product(name: "JXKit", package: "JXKit")
            ],
            resources: [
                .process("Resources")
            ],
        ),
    ],
)
