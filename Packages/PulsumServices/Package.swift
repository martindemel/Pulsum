// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumServices",
    platforms: [
        .iOS("26.0"),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumServices",
            targets: ["PulsumServices"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumData"),
        .package(path: "../PulsumML")
    ],
    targets: [
        .target(
            name: "PulsumServices",
            dependencies: [
                "PulsumData",
                "PulsumML"
            ],
            path: "Sources",
            resources: [
                .process("PulsumServices/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("FoundationModels")
            ]
        ),
        .testTarget(
            name: "PulsumServicesTests",
            dependencies: ["PulsumServices"],
            path: "Tests"
        )
    ]
)
