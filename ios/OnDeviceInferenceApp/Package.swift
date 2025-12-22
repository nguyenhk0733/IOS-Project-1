// swift-tools-version: 5.10
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "OnDeviceInferenceApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "OnDeviceInference",
            targets: ["App"],
            bundleIdentifier: "com.example.ondeviceinference",
            teamIdentifier: "" ,
            displayVersion: "0.1.0",
            bundleVersion: "1",
            appIcon: .placeholder(
                emoji: "🤖",
                color: .orange
            ),
            accentColor: .presetColor(.orange),
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen",
                "NSCameraUsageDescription": "Camera access is needed to capture images for on-device inference.",
                "NSPhotoLibraryUsageDescription": "Photo library access lets you pick images to analyze on-device."
            ]),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown,
                .landscapeRight,
                .landscapeLeft
            ]
        )
    ],
    dependencies: [
        // Add Swift Package Manager dependencies here, e.g. model/runtime packages
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "Onboarding",
                "Capture",
                "Result",
                "History",
                "Settings"
            ],
            path: "Sources/App",
            resources: [
                .process("../Resources")
            ]
        ),
        .target(
            name: "Onboarding",
            dependencies: ["Shared"]
        ),
        .target(
            name: "Capture",
            dependencies: ["Shared"]
        ),
        .target(
            name: "Result",
            dependencies: ["Shared"]
        ),
        .target(
            name: "History",
            dependencies: ["Shared"]
        ),
        .target(
            name: "Settings",
            dependencies: ["Shared"]
        ),
        .target(
            name: "Shared",
            dependencies: [],
            resources: [
                .process("Sources/Shared/Resources")
            ]
        ),
        .testTarget(
            name: "ModelIOTests",
            dependencies: ["Shared"],
            path: "Tests/ModelIOTests",
            resources: [
                .process("TestImages")
            ]
        ),
        .testTarget(
            name: "ViewModelTests",
            dependencies: [
                "Onboarding",
                "Capture",
                "Result",
                "History",
                "Settings",
                "Shared"
            ],
            path: "Tests/ViewModelTests"
        )
    ]
)
