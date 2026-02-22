import Foundation
import RealityKit
import _RealityKit_SwiftUI

@MainActor
class CaptureService: ObservableObject {
    @Published var session: ObjectCaptureSession?
    @Published var isReady = false
    @Published var shotCount = 0
    @Published var feedback: Set<ObjectCaptureSession.Feedback> = []

    let imageDirectory: URL
    let checkpointDirectory: URL

    private var stateMonitorTask: Task<Void, Never>?
    private var feedbackMonitorTask: Task<Void, Never>?

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
                case .ready, .detecting, .capturing:
                    self.isReady = true
                case .failed:
                    self.isReady = false
                default:
                    break
                }
                self.shotCount = session.numberOfShotsTaken
            }
        }

        feedbackMonitorTask = Task { [weak self] in
            for await feedback in session.feedbackUpdates {
                guard let self else { return }
                self.feedback = feedback
                self.shotCount = session.numberOfShotsTaken
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
        session = nil
        isReady = false
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
