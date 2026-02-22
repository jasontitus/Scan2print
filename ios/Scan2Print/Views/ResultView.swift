import SwiftUI

struct ResultView: View {
    let success: Bool
    let message: String
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(success ? .green : .red)

            Text(success ? "Print Started!" : "Something Went Wrong")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onReset) {
                Text("Scan Another Object")
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
}
