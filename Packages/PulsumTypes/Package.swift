// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumTypes",
    platforms: [
        .iOS("26.0"),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumTypes",
            targets: ["PulsumTypes"]
        )
    ],
    targets: [
        .target(
            name: "PulsumTypes",
            path: "Sources"
        )
    ]
)
