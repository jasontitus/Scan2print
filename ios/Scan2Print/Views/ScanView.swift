import SwiftUI
import os
import RealityKit
import _RealityKit_SwiftUI

private let log = LogStore.shared
private let logCategory = "ScanView"

struct ScanView: View {
    @ObservedObject var captureService: CaptureService
    let onFinished: () -> Void
    let onCancel: () -> Void

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
                // Top bar: cancel + phase + shot counter
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    shotCounter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Phase label so user knows what's happening
                phaseLabel
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

                // Object confirmation button — shown when an object is detected
                if captureService.phase == .detecting {
                    Button(action: {
                        log.info("User tapped 'Scan This Object'", category: logCategory)
                        captureService.confirmCapture()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Scan This Object")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.green)
                        .clipShape(Capsule())
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
                }

                // Finish button
                if captureService.shotCount > 0 {
                    Button(action: {
                        captureService.finish()
                        onFinished()
                    }) {
                        HStack(spacing: 8) {
                            Text("Finish Scan")
                            if captureService.shotCount < 20 {
                                Text("(\(captureService.shotCount) — need more)")
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
            .animation(.easeInOut(duration: 0.25), value: captureService.phase)
        }
        .onAppear {
            log.info("ScanView appeared — starting capture", category: logCategory)
            captureService.start()
        }
        .onChange(of: captureService.phase) { oldPhase, newPhase in
            log.info("ScanView phase changed: \(String(describing: oldPhase)) → \(String(describing: newPhase))", category: logCategory)
        }
        .onChange(of: captureService.shotCount) { oldCount, newCount in
            log.info("ScanView shotCount changed: \(oldCount) → \(newCount)", category: logCategory)
        }
    }

    // MARK: - Phase label

    @ViewBuilder
    private var phaseLabel: some View {
        let text: String = switch captureService.phase {
        case .initializing: "Starting..."
        case .ready: "Point at an object"
        case .detecting: "Object detected — tap to start scanning"
        case .capturing: "Scanning — move slowly around object"
        case .finishing: "Finishing..."
        case .failed: "Scanner failed"
        }

        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
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
        // Lighting is the top blocker — show it first
        if fb.contains(.environmentLowLight) { return "⚠ Need more light — scanning can't start" }
        if fb.contains(.environmentTooDark) { return "⚠ Too dark — turn on more lights" }
        if fb.contains(.movingTooFast) { return "Slow down" }
        if fb.contains(.objectTooClose) { return "Move farther away" }
        if fb.contains(.objectTooFar) { return "Move closer" }
        if fb.contains(.objectNotFlippable) { return "Try a different angle" }
        return nil
    }
}
