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

            Section(header: Text("Preference display")) {
                Picker("Name formatting", selection: $viewModel.formattingStyle) {
                    ForEach(TextFormattingStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                ForEach(viewModel.topUsers) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.formattedName(using: viewModel.formattingStyle))
                            .font(.headline)
                        Text(user.capability)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section(header: Text("Benchmark"), footer: Text(viewModel.benchmark.formattedSummary())) {
                Button("Run on-device benchmark") {
                    Task { await viewModel.runBenchmarkProbe() }
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Label("Samples", systemImage: "waveform.path.ecg")
                    Spacer()
                    Text("\(viewModel.benchmark.sampleCount)")
                        .monospacedDigit()
                }

                if let error = viewModel.benchmarkError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .onAppear { viewModel.refreshBenchmark() }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
