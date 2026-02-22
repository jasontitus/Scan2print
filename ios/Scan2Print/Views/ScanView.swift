import SwiftUI
import RealityKit
import _RealityKit_SwiftUI

struct ScanView: View {
    @ObservedObject var captureService: CaptureService
    let onFinished: () -> Void
    let onCancel: () -> Void

    /// Rough minimum shots for a decent reconstruction.
    private let targetShots = 50

    private var progress: Double {
        min(Double(captureService.shotCount) / Double(targetShots), 1.0)
    }

    private var ringColor: Color {
        switch captureService.shotCount {
        case ..<20: return .red
        case ..<40: return .orange
        default: return .green
        }
    }

    var body: some View {
        ZStack {
            if let session = captureService.session {
                ObjectCaptureView(session: session)
                    .ignoresSafeArea()
            } else {
                ProgressView("Starting scanner...")
            }

            VStack {
                // Top bar: cancel + shot counter
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    if captureService.session != nil {
                        shotCounter
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Feedback hint
                if let hint = feedbackHint {
                    Text(hint)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 8)
                }

                // Finish button
                if captureService.isReady {
                    Button(action: {
                        captureService.finish()
                        onFinished()
                    }) {
                        HStack(spacing: 8) {
                            Text("Finish Scan")
                            if captureService.shotCount < 20 {
                                Text("(\(captureService.shotCount) shots — more is better)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(captureService.shotCount < 20 ? .gray : .blue)
                        .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            captureService.start()
        }
    }

    // MARK: - Shot counter ring

    private var shotCounter: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(captureService.shotCount)")
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial, in: Circle())
        .animation(.easeInOut(duration: 0.3), value: captureService.shotCount)
    }

    // MARK: - Feedback

    private var feedbackHint: String? {
        let fb = captureService.feedback
        if fb.contains(.movingTooFast) { return "Slow down" }
        if fb.contains(.objectTooClose) { return "Move farther away" }
        if fb.contains(.objectTooFar) { return "Move closer" }
        if fb.contains(.environmentTooDark) { return "Need more light" }
        if fb.contains(.objectNotFlippable) { return "Try a different angle" }
        if captureService.shotCount == 0 && captureService.isReady {
            return "Move around the object slowly"
        }
        return nil
    }
}
