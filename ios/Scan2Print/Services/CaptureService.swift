import Foundation
import os
import RealityKit
import _RealityKit_SwiftUI

private let logger = Logger(subsystem: "com.scan2print", category: "CaptureService")

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
        logger.info("CaptureService init — images: \(self.imageDirectory.path()), checkpoints: \(self.checkpointDirectory.path())")
    }

    func start() {
        logger.info("start() called — cleaning directories")
        cleanDirectories()

        let isSupported = ObjectCaptureSession.isSupported
        logger.info("ObjectCaptureSession.isSupported = \(isSupported)")
        guard isSupported else {
            logger.error("ObjectCaptureSession is NOT supported on this device")
            phase = .failed
            return
        }

        let session = ObjectCaptureSession()
        self.session = session
        logger.info("ObjectCaptureSession created, calling session.start()")

        var config = ObjectCaptureSession.Configuration()
        config.checkpointDirectory = checkpointDirectory
        session.start(imagesDirectory: imageDirectory, configuration: config)
        logger.info("session.start() returned — monitoring state updates")

        stateMonitorTask = Task { [weak self] in
            for await state in session.stateUpdates {
                guard let self else { return }
                logger.info("stateUpdate received: \(String(describing: state))")
                switch state {
                case .ready:
                    self.phase = .ready
                    logger.info("Phase → ready — waiting for object detection")
                case .detecting:
                    self.phase = .detecting
                    logger.info("Phase → detecting — object detected, calling startCapturing()")
                    session.startCapturing()
                case .capturing:
                    self.phase = .capturing
                    logger.info("Phase → capturing — session is now taking shots")
                case .finishing:
                    self.phase = .finishing
                    logger.info("Phase → finishing")
                case .failed(let error):
                    self.phase = .failed
                    logger.error("Phase → failed: \(String(describing: error))")
                default:
                    logger.warning("Unhandled state: \(String(describing: state))")
                    break
                }
            }
            logger.info("stateUpdates stream ended")
        }

        feedbackMonitorTask = Task { [weak self] in
            for await feedback in session.feedbackUpdates {
                guard let self else { return }
                logger.info("Feedback update: \(feedback.map { String(describing: $0) }.joined(separator: ", "))")
                self.feedback = feedback
            }
        }

        // Poll shot count since it has no async sequence
        shotCountTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let count = session.numberOfShotsTaken
                if count != self.shotCount {
                    logger.info("Shot count changed: \(self.shotCount) → \(count)")
                    self.shotCount = count
                }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    func finish() {
        logger.info("finish() called — shotCount=\(self.shotCount)")
        session?.finish()
    }

    func reset() {
        logger.info("reset() called")
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
            do {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
                logger.info("Created directory: \(dir.path())")
            } catch {
                logger.error("Failed to create directory \(dir.path()): \(error.localizedDescription)")
            }
        }
    }
}
