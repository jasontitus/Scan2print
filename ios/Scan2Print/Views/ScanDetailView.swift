import SwiftUI

struct ScanDetailView: View {
    @ObservedObject var scanStore: ScanStore
    let scanId: UUID
    @Environment(\.dismiss) private var dismiss

    private let network = NetworkService()

    private var scan: SavedScan? {
        scanStore.scans.first { $0.id == scanId }
    }

    var body: some View {
        Group {
            if let scan {
                VStack(spacing: 0) {
                    ModelPreviewView(modelURL: scanStore.modelURL(for: scan))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    detailPanel(for: scan)
                }
            } else {
                ContentUnavailableView("Scan Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(scan?.name ?? "Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if scan != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        scanStore.deleteScan(id: scanId)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Detail Panel

    private func detailPanel(for scan: SavedScan) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scan.name)
                        .font(.headline)
                    Text(scan.dateCreated, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(for: scan.uploadStatus)
            }

            actionButton(for: scan)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Status Badge

    @ViewBuilder
    private func statusBadge(for status: UploadStatus) -> some View {
        switch status {
        case .local:
            badge("Local", color: .gray)
        case .uploading:
            badge("Uploading", color: .blue)
        case .slicing:
            badge("Slicing", color: .blue)
        case .readyToPrint:
            badge("Ready", color: .orange)
        case .printing:
            badge("Printing", color: .blue)
        case .printed:
            badge("Printed", color: .green)
        case .failed:
            badge("Failed", color: .red)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Action Button

    @ViewBuilder
    private func actionButton(for scan: SavedScan) -> some View {
        switch scan.uploadStatus {
        case .local, .failed:
            Button(action: { startUpload(scan: scan) }) {
                Text("Upload & Print")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .clipShape(Capsule())
            }

        case .readyToPrint(let jobId):
            Button(action: { startPrint(scan: scan, jobId: jobId) }) {
                Text("Print")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .clipShape(Capsule())
            }

        case .uploading, .slicing, .printing:
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

        case .printed:
            Label("Printed", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
    }

    // MARK: - Network Actions

    private func startUpload(scan: SavedScan) {
        let modelURL = scanStore.modelURL(for: scan)
        scanStore.updateStatus(id: scan.id, status: .uploading)

        Task {
            do {
                let response = try await network.upload(fileURL: modelURL)
                scanStore.updateStatus(id: scan.id, status: .slicing(jobId: response.jobId))
                let status = try await network.pollUntilSliced(jobId: response.jobId)
                scanStore.updateStatus(id: scan.id, status: .readyToPrint(jobId: status.jobId))
            } catch {
                scanStore.updateStatus(id: scan.id, status: .failed(message: error.localizedDescription))
            }
        }
    }

    private func startPrint(scan: SavedScan, jobId: String) {
        scanStore.updateStatus(id: scan.id, status: .printing(jobId: jobId))

        Task {
            do {
                _ = try await network.triggerPrint(jobId: jobId)
                scanStore.updateStatus(id: scan.id, status: .printed)
            } catch {
                scanStore.updateStatus(id: scan.id, status: .failed(message: error.localizedDescription))
            }
        }
    }
}
