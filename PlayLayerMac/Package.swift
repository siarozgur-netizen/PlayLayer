// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PlayLayerMac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "Lumi",
            targets: ["PlayLayerMac"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "PlayLayerMac",
            resources: [
                .process("Resources"),
            ]
        ),
    ],
)
