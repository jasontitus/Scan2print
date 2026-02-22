import SwiftUI

struct ScanSavedView: View {
    @ObservedObject var scanStore: ScanStore
    let scanId: UUID
    let onScanAnother: () -> Void
    let onViewLibrary: () -> Void

    private var scan: SavedScan? {
        scanStore.scans.first { $0.id == scanId }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let scan {
                let url = scanStore.thumbnailURL(for: scan)
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.blue)
                }
            }

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Scan Saved!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your 3D model has been saved to the library.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onScanAnother) {
                    Text("Scan Another")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .clipShape(Capsule())
                }

                Button(action: onViewLibrary) {
                    Text("View in Library")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}
