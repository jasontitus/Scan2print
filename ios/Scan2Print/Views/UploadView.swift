import SwiftUI

struct UploadView: View {
    let status: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text(status)
                .font(.headline)

            Text("Communicating with server...")
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
