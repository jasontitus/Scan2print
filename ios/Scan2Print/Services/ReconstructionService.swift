import Foundation
import RealityKit

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

        photogrammetryTask = Task.detached { [weak self] in
            do {
                let session = try PhotogrammetrySession(input: imagesDirectory)

                try session.process(requests: [
                    .modelFile(url: outputFile)
                ])

                for try await output in session.outputs {
                    switch output {
                    case .requestProgress(_, fractionComplete: let fraction):
                        await MainActor.run {
                            self?.progress = fraction
                        }
                    case .requestComplete(_, let result):
                        if case .modelFile(let url) = result {
                            await MainActor.run {
                                self?.outputURL = url
                                self?.progress = 1.0
                            }
                        }
                    case .requestError(_, let err):
                        await MainActor.run {
                            self?.error = err.localizedDescription
                        }
                    default:
                        break
                    }
                }
            } catch {
                await MainActor.run {
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    func cancel() {
        photogrammetryTask?.cancel()
        photogrammetryTask = nil
    }
}
