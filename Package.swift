// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LifePilot",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "LifePilotCore", targets: ["LifePilotCore"]),
    ],
    targets: [
        .target(
            name: "LifePilotCore",
            path: "Core"
        ),
        .testTarget(
            name: "LifePilotCoreTests",
            dependencies: ["LifePilotCore"],
            path: "Tests/Core"
        ),
    ]
)
