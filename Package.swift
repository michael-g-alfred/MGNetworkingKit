// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MGNetworkingKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "MGNetworkingKit",
            targets: ["MGNetworkingKit"]
        ),
    ],
    targets: [
        .target(
            name: "MGNetworkingKit"
        ),

    ],
    swiftLanguageModes: [.v6]
)
