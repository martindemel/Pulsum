// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PulsumData",
    platforms: [
        .iOS(.v26),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PulsumData",
            targets: ["PulsumData"]
        )
    ],
    dependencies: [
        .package(path: "../PulsumML")
    ],
    targets: [
        .target(
            name: "PulsumData",
            dependencies: [
                "PulsumML"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PulsumDataTests",
            dependencies: ["PulsumData"],
            path: "Tests",
            resources: [
                .copy("PulsumDataTests/Resources")
            ]
        )
    ]
)
