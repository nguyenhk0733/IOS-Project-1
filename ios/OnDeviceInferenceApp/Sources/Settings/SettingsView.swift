import SwiftUI
import Shared

public struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section(header: L10n.text("model_management_section"), footer: Text(viewModel.modelInfo.remoteStatus)) {
                HStack {
                    Label {
                        L10n.text("bundled_model")
                    } icon: {
                        Image(systemName: "shippingbox")
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(viewModel.modelInfo.bundledName)
                            .font(.headline)
                        Text("v\(viewModel.modelInfo.bundledVersion)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: viewModel.modelInfo.remoteEndpoint) {
                    Label {
                        Text(viewModel.modelInfo.remoteStatus)
                    } icon: {
                        Image(systemName: "network")
                            .accessibilityHidden(true)
                    }
                }
                .tint(.accentColor)
            }

            Section(header: L10n.text("preferences_section")) {
                Toggle(L10n.string("enable_telemetry"), isOn: $viewModel.settings.enableTelemetry)
                Toggle(L10n.string("auto_save_history"), isOn: $viewModel.settings.autoSaveHistory)
                Picker(L10n.string("compute_unit"), selection: $viewModel.settings.preferredComputeUnit) {
                    ForEach(ComputeUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
            }

            Section(header: L10n.text("feedback_privacy_section")) {
                Toggle(L10n.string("enable_haptics"), isOn: $viewModel.settings.enableHaptics)
                Toggle(L10n.string("privacy_mode"), isOn: $viewModel.settings.privacyModeEnabled)
                    .help(L10n.string("privacy_mode_help"))
            }

            Section(header: L10n.text("language_section")) {
                Picker(L10n.string("app_language"), selection: $viewModel.settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(header: L10n.text("preference_display_section")) {
                Picker(L10n.string("name_formatting"), selection: $viewModel.formattingStyle) {
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

            Section(header: L10n.text("benchmark_section"), footer: Text(viewModel.benchmark.formattedSummary())) {
                Button(L10n.string("run_benchmark")) {
                    Task { await viewModel.runBenchmarkProbe() }
                }
                .buttonStyle(.borderedProminent)

                HStack {
                    Label {
                        L10n.text("samples")
                    } icon: {
                        Image(systemName: "waveform.path.ecg")
                            .accessibilityHidden(true)
                    }
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
        .navigationTitle(L10n.string("settings_navigation_title"))
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(repository: MockInferenceRepository()))
    }
}
