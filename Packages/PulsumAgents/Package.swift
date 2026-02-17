// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumAgents",
    defaultLocalization: "en",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15)
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
        .package(path: "../PulsumML"),
        .package(path: "../PulsumTypes")
    ],
    targets: [
        .target(
            name: "PulsumAgents",
            dependencies: [
                "PulsumData",
                "PulsumServices",
                "PulsumML",
                "PulsumTypes"
            ],
            path: "Sources",
            resources: [
                .process("PulsumAgents/PrivacyInfo.xcprivacy"),
                .process("PulsumAgents/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PulsumAgentsTests",
            dependencies: [
                "PulsumAgents",
                "PulsumServices",
                "PulsumML",
                "PulsumTypes"
            ],
            path: "Tests",
            resources: [
                .process("PulsumAgentsTests/Resources")
            ]
        )
    ]
)
