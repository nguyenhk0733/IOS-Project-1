# On-Device Inference iOS App (SwiftUI)

Swift Package Manager-based SwiftUI application scaffolded for on-device inference workflows.
Includes modular MVVM structure for onboarding, capture, result, history, and settings screens.

## Structure
- `Package.swift`: Defines the iOS application product and target graph.
- `Sources/App`: App entry point and composition root.
- `Sources/Shared`: Shared models and inference service interfaces.
- Feature modules: `Onboarding`, `Capture`, `Result`, `History`, `Settings`.

## Getting Started
1. Open the package in Xcode 15+ using "Open Package".
2. Replace `MockOnDeviceInferenceService` with your on-device model runtime implementation.
3. Wire actual capture and persistence logic to the feature view models.
