// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumData",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "PulsumData",
            targets: ["PulsumData"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumML"),
        .package(path: "../PulsumTypes")
    ],
    targets: [
        .target(
            name: "PulsumData",
            dependencies: [
                "PulsumML",
                "PulsumTypes"
            ],
            path: "Sources",
            resources: [
                .process("PulsumData/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "PulsumDataTests",
            dependencies: ["PulsumData", "PulsumTypes"],
            path: "Tests",
            resources: [
                .copy("PulsumDataTests/Resources")
            ]
        )
    ]
)
