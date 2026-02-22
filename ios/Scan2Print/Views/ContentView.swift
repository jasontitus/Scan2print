import SwiftUI

struct ContentView: View {
    @StateObject private var scanStore = ScanStore()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanFlowView(scanStore: scanStore, selectedTab: $selectedTab)
                .tabItem { Label("Scan", systemImage: "viewfinder") }
                .tag(0)

            LibraryView(scanStore: scanStore)
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }
                .tag(1)

            LogViewerView()
                .tabItem { Label("Logs", systemImage: "doc.text") }
                .tag(2)
        }
        .onAppear {
            scanStore.load()
        }
    }
}
