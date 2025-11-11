// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumML",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumML",
            targets: ["PulsumML"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PulsumML",
            path: "Sources",
            exclude: [
                "PulsumML/AFM/README_FoundationModels.md",
                "PulsumML/Resources/README_CreateModel.md"
            ],
            resources: [
                .process("PulsumML/Resources/PulsumFallbackEmbedding.mlmodel"),
                .process("PulsumML/Resources/PulsumSentimentCoreML.mlmodel")
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels"),
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
