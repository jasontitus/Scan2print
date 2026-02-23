import Foundation
import os
import RealityKit
import _RealityKit_SwiftUI

private let log = LogStore.shared
private let logCategory = "CaptureService"

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
        log.info("CaptureService init — images: \(imageDirectory.path()), checkpoints: \(checkpointDirectory.path())", category: logCategory)
    }

    func start() {
        log.info("start() called — cleaning directories", category: logCategory)
        cleanDirectories()

        let isSupported = ObjectCaptureSession.isSupported
        log.info("ObjectCaptureSession.isSupported = \(isSupported)", category: logCategory)
        guard isSupported else {
            log.error("ObjectCaptureSession is NOT supported on this device", category: logCategory)
            phase = .failed
            return
        }

        let session = ObjectCaptureSession()
        self.session = session
        log.info("ObjectCaptureSession created, calling session.start()", category: logCategory)

        var config = ObjectCaptureSession.Configuration()
        config.checkpointDirectory = checkpointDirectory
        session.start(imagesDirectory: imageDirectory, configuration: config)
        log.info("session.start() returned — reading initial state", category: logCategory)

        // Read the current state immediately — stateUpdates only yields
        // FUTURE changes, so we'd miss the initial transition to .ready
        updatePhase(from: session.state)

        stateMonitorTask = Task { [weak self] in
            for await state in session.stateUpdates {
                guard let self else { return }
                log.info("stateUpdate received: \(String(describing: state))", category: logCategory)
                self.updatePhase(from: state)
            }
            log.info("stateUpdates stream ended", category: logCategory)
        }

        feedbackMonitorTask = Task { [weak self] in
            for await feedback in session.feedbackUpdates {
                guard let self else { return }
                log.info("Feedback update: \(feedback.map { String(describing: $0) }.joined(separator: ", "))", category: logCategory)
                self.feedback = feedback
            }
        }

        // Poll shot count since it has no async sequence
        shotCountTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let count = session.numberOfShotsTaken
                if count != self.shotCount {
                    log.info("Shot count changed: \(self.shotCount) → \(count)", category: logCategory)
                    self.shotCount = count
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    /// Called by the user to confirm the detected object and begin capturing.
    func confirmCapture() {
        log.info("confirmCapture() — user confirmed object, calling startCapturing()", category: logCategory)
        session?.startCapturing()
    }

    func finish() {
        log.info("finish() called — shotCount=\(self.shotCount)", category: logCategory)
        session?.finish()
    }

    func reset() {
        log.info("reset() called", category: logCategory)
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

    private func updatePhase(from state: ObjectCaptureSession.CaptureState) {
        log.info("updatePhase from: \(String(describing: state))", category: logCategory)
        switch state {
        case .ready:
            phase = .ready
            log.info("Phase → ready — waiting for object detection", category: logCategory)
        case .detecting:
            phase = .detecting
            log.info("Phase → detecting — object detected, waiting for user confirmation", category: logCategory)
        case .capturing:
            phase = .capturing
            log.info("Phase → capturing — session is now taking shots", category: logCategory)
        case .finishing:
            phase = .finishing
            log.info("Phase → finishing", category: logCategory)
        case .failed(let error):
            phase = .failed
            log.error("Phase → failed: \(String(describing: error))", category: logCategory)
        default:
            log.warning("Unhandled state: \(String(describing: state))", category: logCategory)
        }
    }

    private func cleanDirectories() {
        let fm = FileManager.default
        for dir in [imageDirectory, checkpointDirectory] {
            try? fm.removeItem(at: dir)
            do {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                log.info("Created directory: \(dir.path())", category: logCategory)
            } catch {
                log.error("Failed to create directory \(dir.path()): \(error.localizedDescription)", category: logCategory)
            }
        }
    }
}
