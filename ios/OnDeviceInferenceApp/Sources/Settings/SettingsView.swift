import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section(header: Text("Preferences")) {
                Toggle("Enable telemetry", isOn: $viewModel.settings.enableTelemetry)
                Toggle("Auto-save history", isOn: $viewModel.settings.autoSaveHistory)
                Picker("Compute unit", selection: $viewModel.settings.preferredComputeUnit) {
                    ForEach(ComputeUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
