// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PulsumAgents",
    platforms: [
        .iOS(.v26),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumAgents",
            targets: ["PulsumAgents"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumData"),
        .package(path: "../PulsumServices"),
        .package(path: "../PulsumML")
    ],
    targets: [
        .target(
            name: "PulsumAgents",
            dependencies: [
                "PulsumData",
                "PulsumServices",
                "PulsumML"
            ],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        ),
        .testTarget(
            name: "PulsumAgentsTests",
            dependencies: [
                "PulsumAgents",
                "PulsumServices"
            ],
            path: "Tests"
        )
    ]
)
