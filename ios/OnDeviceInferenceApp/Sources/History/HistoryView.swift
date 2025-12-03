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
        List {
            if !favoriteEntries.isEmpty {
                Section("Favorites") {
                    ForEach(favoriteEntries) { entry in
                        row(for: entry)
                    }
                }
            }

            Section("Recent") {
                ForEach(recentEntries) { entry in
                    row(for: entry)
                }
            }
        }
        .overlay(Group {
            if viewModel.entries.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "clock.arrow.circlepath")
            }
        })
        .alert("History Error", isPresented: errorBinding, actions: {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .navigationTitle("History")
    }

    private var favoriteEntries: [HistoryEntry] {
        viewModel.entries.filter { $0.isFavorite }
    }

    private var recentEntries: [HistoryEntry] {
        viewModel.entries.filter { !$0.isFavorite }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented { viewModel.errorMessage = nil }
            }
        )
    }

    private func row(for entry: HistoryEntry) -> some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.result.summary)
                        .font(.headline)
                    Text(dateFormatter.string(from: entry.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(entry.isFavorite ? "Unfavorite" : "Favorite") {
                viewModel.toggleFavorite(for: entry)
            }
            .tint(entry.isFavorite ? .gray : .orange)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(viewModel: HistoryViewModel(entries: [
            HistoryEntry(id: UUID(), timestamp: Date(), result: InferenceResult(summary: "Preview", confidence: 0.75))
        ]))
    }
}
