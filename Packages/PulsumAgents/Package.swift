// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumAgents",
    platforms: [
        .iOS("26.0"),
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
                .process("PulsumAgents/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels", .when(platforms: [.iOS]))
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
