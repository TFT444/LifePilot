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
        .library(name: "LifePilotDesignSystem", targets: ["LifePilotDesignSystem"]),
        .library(name: "LifePilotGhostBrain", targets: ["LifePilotGhostBrain"]),
        .library(name: "LifePilotServices", targets: ["LifePilotServices"]),
        .library(name: "LifePilotMocks", targets: ["LifePilotMocks"]),
        .library(name: "LifePilotFeatures", targets: ["LifePilotFeatures"]),
        .library(name: "LifePilotAppShell", targets: ["LifePilotAppShell"]),
    ],
    targets: [
        // MARK: - Domain layer (framework-agnostic, per docs/ARCHITECTURE.md)

        .target(
            name: "LifePilotCore",
            path: "Core"
        ),
        .testTarget(
            name: "LifePilotCoreTests",
            dependencies: ["LifePilotCore"],
            path: "Tests/Core"
        ),

        .target(
            name: "LifePilotGhostBrain",
            dependencies: ["LifePilotCore"],
            path: "GhostBrain"
        ),
        .testTarget(
            name: "LifePilotGhostBrainTests",
            dependencies: ["LifePilotGhostBrain", "LifePilotCore"],
            path: "Tests/GhostBrain"
        ),

        // MARK: - Service layer

        .target(
            name: "LifePilotServices",
            dependencies: ["LifePilotCore"],
            path: "Services"
        ),

        // MARK: - Mocks (test/preview support)

        .target(
            name: "LifePilotMocks",
            dependencies: ["LifePilotCore"],
            path: "Mocks"
        ),
        .testTarget(
            name: "LifePilotMocksTests",
            dependencies: ["LifePilotMocks"],
            path: "Tests/Mocks"
        ),

        // MARK: - Presentation layer (per docs/ARCHITECTURE.md, may import SwiftUI)

        .target(
            name: "LifePilotDesignSystem",
            dependencies: ["LifePilotCore"],
            path: "DesignSystem"
        ),
        .testTarget(
            name: "LifePilotDesignSystemTests",
            dependencies: ["LifePilotDesignSystem"],
            path: "Tests/DesignSystem"
        ),

        .target(
            name: "LifePilotFeatures",
            dependencies: [
                "LifePilotCore",
                "LifePilotGhostBrain",
                "LifePilotDesignSystem",
                "LifePilotMocks",
            ],
            path: "Features"
        ),
        .testTarget(
            name: "LifePilotFeaturesTests",
            dependencies: ["LifePilotFeatures", "LifePilotCore", "LifePilotGhostBrain"],
            path: "Tests/Features"
        ),

        // MARK: - App shell (composition root, root navigation)

        .target(
            name: "LifePilotAppShell",
            dependencies: [
                "LifePilotCore",
                "LifePilotGhostBrain",
                "LifePilotDesignSystem",
                "LifePilotFeatures",
            ],
            path: "AppShell"
        ),
        .testTarget(
            name: "LifePilotAppShellTests",
            dependencies: ["LifePilotAppShell"],
            path: "Tests/AppShell"
        ),
    ]
)
