// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumML",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "PulsumML",
            targets: ["PulsumML"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumTypes")
    ],
    targets: [
        .target(
            name: "PulsumML",
            dependencies: [
                "PulsumTypes"
            ],
            path: "Sources",
            exclude: [
                "PulsumML/AFM/README_FoundationModels.md",
                "PulsumML/Resources/README_CreateModel.md"
            ],
            resources: [
                .process("PulsumML/Resources/PulsumFallbackEmbedding.mlmodel"),
                .process("PulsumML/Resources/PulsumSentimentCoreML.mlmodel"),
                .process("PulsumML/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("Accelerate")
            ]
        ),
        .testTarget(
            name: "PulsumMLTests",
            dependencies: ["PulsumML"],
            path: "Tests"
        )
    ]
)
