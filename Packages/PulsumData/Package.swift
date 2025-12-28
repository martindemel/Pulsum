// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PulsumData",
    platforms: [
        .iOS("26.0"),
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
            path: "Sources",
            resources: [
                .process("PulsumData/PrivacyInfo.xcprivacy"),
                .process("PulsumData/Resources/Pulsum.xcdatamodeld"),
                .process("PulsumData/Resources/PulsumCompiled.momd")
            ]
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
