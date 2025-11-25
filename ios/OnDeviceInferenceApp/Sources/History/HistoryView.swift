import SwiftUI
import Shared

public struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    private let dateFormatter: DateFormatter

    public init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.dateFormatter = formatter
    }

    public var body: some View {
        List(viewModel.entries) { entry in
            VStack(alignment: .leading) {
                Text(entry.result.summary)
                    .font(.headline)
                Text(dateFormatter.string(from: entry.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "clock.arrow.circlepath")
            }
        })
        .navigationTitle("History")
    }
}

#Preview {
    NavigationStack {
        HistoryView(viewModel: HistoryViewModel(entries: [
            HistoryEntry(id: UUID(), timestamp: Date(), result: InferenceResult(summary: "Preview", confidence: 0.75))
        ]))
    }
}
