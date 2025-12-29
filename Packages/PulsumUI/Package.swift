// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumUI",
    platforms: [
        .iOS("26.0")
    ],
    products: [
        .library(
            name: "PulsumUI",
            targets: ["PulsumUI"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumAgents"),
        .package(path: "../PulsumData"),
        .package(path: "../PulsumServices"),
        .package(path: "../PulsumTypes")
    ],
    targets: [
        .target(
            name: "PulsumUI",
            dependencies: [
                "PulsumAgents",
                "PulsumData",
                "PulsumServices",
                "PulsumTypes"
            ],
            path: "Sources",
            resources: [
                .process("PulsumUI/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "PulsumUITests",
            dependencies: ["PulsumUI"],
            path: "Tests"
        )
    ]
)
