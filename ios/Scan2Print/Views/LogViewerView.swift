import SwiftUI

struct LogViewerView: View {
    @ObservedObject private var logStore = LogStore.shared

    @State private var selectedCategory: String?
    @State private var selectedLevel: LogLevel?
    @State private var autoScroll = true

    private var categories: [String] {
        Array(Set(logStore.entries.map(\.category))).sorted()
    }

    private var filteredEntries: [LogEntry] {
        logStore.entries.filter { entry in
            if let cat = selectedCategory, entry.category != cat { return false }
            if let lvl = selectedLevel, entry.level != lvl { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .navigationTitle("Logs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { logStore.clear() }) {
                        Text("Clear")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: logStore.allText()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category filters
                filterChip("All", isActive: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(categories, id: \.self) { cat in
                    filterChip(cat, isActive: selectedCategory == cat) {
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }

                Divider()
                    .frame(height: 20)

                // Level filters
                levelChip(.error)
                levelChip(.warning)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func filterChip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundColor(isActive ? .accentColor : .secondary)
                .clipShape(Capsule())
        }
    }

    private func levelChip(_ level: LogLevel) -> some View {
        let isActive = selectedLevel == level
        return Button {
            selectedLevel = isActive ? nil : level
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(colorForLevel(level))
                    .frame(width: 6, height: 6)
                Text(level.rawValue)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isActive ? colorForLevel(level).opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundColor(isActive ? colorForLevel(level) : .secondary)
            .clipShape(Capsule())
        }
    }

    private func colorForLevel(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        }
    }

    // MARK: - Log list

    private var logList: some View {
        ScrollViewReader { proxy in
            List(filteredEntries) { entry in
                logRow(entry)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                    .id(entry.id)
            }
            .listStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .onChange(of: logStore.entries.count) { _, _ in
                if autoScroll, let last = filteredEntries.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func logRow(_ entry: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(timeString(entry.timestamp))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(entry.category)
                .foregroundColor(.accentColor)
                .frame(width: 60, alignment: .leading)
                .lineLimit(1)

            Text(entry.message)
                .foregroundColor(entry.color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Logs Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start a scan to see logs here.")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
