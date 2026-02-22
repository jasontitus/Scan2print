import Foundation
import RealityKit
import _RealityKit_SwiftUI

enum CapturePhase: Equatable {
    case initializing
    case ready
    case detecting
    case capturing
    case finishing
    case failed
}

@MainActor
class CaptureService: ObservableObject {
    @Published var session: ObjectCaptureSession?
    @Published var phase: CapturePhase = .initializing
    @Published var shotCount = 0
    @Published var feedback: Set<ObjectCaptureSession.Feedback> = []

    let imageDirectory: URL
    let checkpointDirectory: URL

    private var stateMonitorTask: Task<Void, Never>?
    private var feedbackMonitorTask: Task<Void, Never>?
    private var shotCountTask: Task<Void, Never>?

    init() {
        let base = FileManager.default.temporaryDirectory.appending(path: "scan2print", directoryHint: .isDirectory)
        imageDirectory = base.appending(path: "images", directoryHint: .isDirectory)
        checkpointDirectory = base.appending(path: "checkpoints", directoryHint: .isDirectory)
    }

    func start() {
        cleanDirectories()

        let session = ObjectCaptureSession()
        self.session = session

        session.start(imagesDirectory: imageDirectory)

        stateMonitorTask = Task { [weak self] in
            for await state in session.stateUpdates {
                guard let self else { return }
                switch state {
                case .ready:
                    self.phase = .ready
                case .detecting:
                    self.phase = .detecting
                case .capturing:
                    self.phase = .capturing
                case .finishing:
                    self.phase = .finishing
                case .failed:
                    self.phase = .failed
                default:
                    break
                }
            }
        }

        feedbackMonitorTask = Task { [weak self] in
            for await feedback in session.feedbackUpdates {
                guard let self else { return }
                self.feedback = feedback
            }
        }

        // Poll shot count since it has no async sequence
        shotCountTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let count = session.numberOfShotsTaken
                if count != self.shotCount {
                    self.shotCount = count
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    func finish() {
        session?.finish()
    }

    func reset() {
        stateMonitorTask?.cancel()
        stateMonitorTask = nil
        feedbackMonitorTask?.cancel()
        feedbackMonitorTask = nil
        shotCountTask?.cancel()
        shotCountTask = nil
        session = nil
        phase = .initializing
        shotCount = 0
        feedback = []
    }

    private func cleanDirectories() {
        let fm = FileManager.default
        for dir in [imageDirectory, checkpointDirectory] {
            try? fm.removeItem(at: dir)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}
