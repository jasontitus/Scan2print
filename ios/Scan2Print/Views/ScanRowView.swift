import SwiftUI

struct ScanRowView: View {
    let scan: SavedScan
    let thumbnailURL: URL

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "cube.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(scan.name)
                    .font(.headline)

                Text(scan.dateCreated, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusBadge
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch scan.uploadStatus {
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
}
