// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "OnDeviceInferenceCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OnDeviceInferenceCore",
            targets: ["Shared",
                      "Onboarding",
                      "Capture",
                      "Result",
                      "History",
                      "Settings"]
        )
    ],
    targets: [
        // MARK: - Shared core
        .target(
            name: "Shared",
            path: "Sources/Shared",
            resources: [
                .process("Resources")
            ]
        ),

        // MARK: - Feature modules (logic only)
        .target(
            name: "Onboarding",
            dependencies: ["Shared"],
            path: "Sources/Onboarding"
        ),
        .target(
            name: "Capture",
            dependencies: ["Shared"],
            path: "Sources/Capture"
        ),
        .target(
            name: "Result",
            dependencies: ["Shared"],
            path: "Sources/Result"
        ),
        .target(
            name: "History",
            dependencies: ["Shared"],
            path: "Sources/History"
        ),
        .target(
            name: "Settings",
            dependencies: ["Shared"],
            path: "Sources/Settings"
        ),

        // MARK: - Tests
        .testTarget(
            name: "ModelIOTests",
            dependencies: [
                "Shared",
                "Onboarding",
                "Capture",
                "Result",
                "History",
                "Settings"
            ],
            path: "Tests/ModelIOTests",
            resources: [
                .process("TestImages")
            ]
        )
    ]
)

