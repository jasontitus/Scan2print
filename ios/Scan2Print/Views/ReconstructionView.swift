import SwiftUI

struct ReconstructionView: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: progress) {
                Text("Reconstructing 3D Model")
                    .font(.headline)
            } currentValueLabel: {
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .monospacedDigit()
            }
            .padding(.horizontal, 40)

            Text("Processing images into a 3D model.\nThis may take a minute...")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
