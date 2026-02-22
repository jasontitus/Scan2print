import Foundation
import RealityKit

private let log = LogStore.shared
private let logCategory = "Reconstruction"

@MainActor
class ReconstructionService: ObservableObject {
    @Published var progress: Double = 0
    @Published var outputURL: URL?
    @Published var error: String?

    private var photogrammetryTask: Task<Void, Never>?

    func reconstruct(imagesDirectory: URL) {
        let outputDir = FileManager.default.temporaryDirectory
            .appending(path: "scan2print/output", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let outputFile = outputDir.appending(path: "model.obj")
        try? FileManager.default.removeItem(at: outputFile)

        log.info("Starting reconstruction from \(imagesDirectory.path())", category: logCategory)

        photogrammetryTask = Task.detached { [weak self] in
            do {
                let session = try PhotogrammetrySession(input: imagesDirectory)
                await log.info("PhotogrammetrySession created, processing...", category: logCategory)

                try session.process(requests: [
                    .modelFile(url: outputFile)
                ])

                for try await output in session.outputs {
                    switch output {
                    case .requestProgress(_, fractionComplete: let fraction):
                        await MainActor.run {
                            self?.progress = fraction
                        }
                        if Int(fraction * 100) % 25 == 0 {
                            await log.info("Reconstruction progress: \(Int(fraction * 100))%", category: logCategory)
                        }
                    case .requestComplete(_, let result):
                        if case .modelFile(let url) = result {
                            await log.info("Reconstruction complete: \(url.path())", category: logCategory)
                            await MainActor.run {
                                self?.outputURL = url
                                self?.progress = 1.0
                            }
                        }
                    case .requestError(_, let err):
                        await log.error("Reconstruction error: \(err.localizedDescription)", category: logCategory)
                        await MainActor.run {
                            self?.error = err.localizedDescription
                        }
                    default:
                        break
                    }
                }
            } catch {
                await log.error("PhotogrammetrySession failed: \(error.localizedDescription)", category: logCategory)
                await MainActor.run {
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    func cancel() {
        log.info("Reconstruction cancelled", category: logCategory)
        photogrammetryTask?.cancel()
        photogrammetryTask = nil
    }
}
