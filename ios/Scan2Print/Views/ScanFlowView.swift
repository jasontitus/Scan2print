import SwiftUI

struct ScanFlowView: View {
    @ObservedObject var scanStore: ScanStore
    @Binding var selectedTab: Int

    @StateObject private var captureService = CaptureService()
    @StateObject private var reconstructionService = ReconstructionService()
    @State private var state: ScanState = .idle

    var body: some View {
        Group {
            switch state {
            case .idle:
                idleView

            case .scanning:
                ScanView(captureService: captureService) {
                    startReconstruction()
                }

            case .reconstructing(let progress):
                ReconstructionView(progress: progress)

            case .saved(let scanId):
                ScanSavedView(
                    scanStore: scanStore,
                    scanId: scanId,
                    onScanAnother: { reset() },
                    onViewLibrary: {
                        reset()
                        selectedTab = 1
                    }
                )

            default:
                // Upload/print states no longer live here
                EmptyView()
            }
        }
        .animation(.default, value: state)
        .onChange(of: reconstructionService.progress) { _, newValue in
            if case .reconstructing = state {
                state = .reconstructing(progress: newValue)
            }
        }
        .onChange(of: reconstructionService.outputURL) { _, url in
            if let url {
                saveScan(modelURL: url)
            }
        }
        .onChange(of: reconstructionService.error) { _, error in
            if let error {
                state = .failed(message: error)
            }
        }
    }

    // MARK: - Subviews

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "cube.transparent")
                .font(.system(size: 72))
                .foregroundStyle(.blue)

            Text("Scan2Print")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Scan an object, save it, and print later.")
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: { state = .scanning }) {
                Text("Start Scan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func startReconstruction() {
        state = .reconstructing(progress: 0)
        reconstructionService.reconstruct(imagesDirectory: captureService.imageDirectory)
    }

    private func saveScan(modelURL: URL) {
        let name = "Scan \(scanStore.scans.count + 1)"
        let id = scanStore.addScan(name: name, modelURL: modelURL)
        state = .saved(scanId: id)
    }

    private func reset() {
        captureService.reset()
        reconstructionService.cancel()
        state = .idle
    }
}
