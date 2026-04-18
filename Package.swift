// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DyldPrivate",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v15),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "DyldPrivate",
            targets: ["DyldPrivate"]
        ),
        .library(
            name: "DyldPrivateRuntime",
            targets: ["DyldPrivateRuntime"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/securevale/swift-confidential.git", .upToNextMinor(from: "0.5.0")),
    ],
    targets: [
        .target(
            name: "DyldPrivate"
        ),
        .target(
            name: "DyldPrivateRuntime",
            dependencies: [
                .product(name: "ConfidentialKit", package: "swift-confidential"),
            ]
        ),
        .testTarget(
            name: "DyldPrivateTests",
            dependencies: ["DyldPrivate"]
        ),
        .testTarget(
            name: "DyldPrivateRuntimeTests",
            dependencies: ["DyldPrivateRuntime"]
        ),
    ]
)
