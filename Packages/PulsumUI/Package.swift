// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumUI",
            targets: ["PulsumUI"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumAgents"),
        .package(path: "../PulsumServices"),
        .package(path: "../PulsumData")
    ],
    targets: [
        .target(
            name: "PulsumUI",
            dependencies: [
                "PulsumAgents",
                "PulsumServices",
                "PulsumData"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PulsumUITests",
            dependencies: ["PulsumUI"],
            path: "Tests"
        )
    ]
)
