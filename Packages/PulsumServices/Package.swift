// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumServices",
    platforms: [
        .iOS("26.0"),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "PulsumServices",
            targets: ["PulsumServices"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumData"),
        .package(path: "../PulsumML"),
        .package(path: "../PulsumTypes")
    ],
    targets: [
        .target(
            name: "PulsumServices",
            dependencies: [
                "PulsumData",
                "PulsumML",
                "PulsumTypes"
            ],
            path: "Sources",
            resources: [
                .process("PulsumServices/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "PulsumServicesTests",
            dependencies: ["PulsumServices"],
            path: "Tests"
        )
    ]
)
