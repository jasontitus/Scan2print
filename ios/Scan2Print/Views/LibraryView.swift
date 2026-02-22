import SwiftUI

struct LibraryView: View {
    @ObservedObject var scanStore: ScanStore

    private var sortedScans: [SavedScan] {
        scanStore.scans.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scanStore.scans.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sortedScans) { scan in
                            NavigationLink(value: scan.id) {
                                ScanRowView(
                                    scan: scan,
                                    thumbnailURL: scanStore.thumbnailURL(for: scan)
                                )
                            }
                        }
                        .onDelete(perform: deleteScans)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: UUID.self) { scanId in
                ScanDetailView(scanStore: scanStore, scanId: scanId)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Scans Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Scanned objects will appear here.")
                .foregroundStyle(.secondary)
        }
    }

    private func deleteScans(at offsets: IndexSet) {
        let sorted = sortedScans
        for index in offsets {
            scanStore.deleteScan(id: sorted[index].id)
        }
    }
}
