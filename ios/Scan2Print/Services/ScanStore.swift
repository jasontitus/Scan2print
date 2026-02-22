import Foundation
import SceneKit

@MainActor
class ScanStore: ObservableObject {
    @Published var scans: [SavedScan] = []

    private let fm = FileManager.default

    private var baseDirectory: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "Scan2Print", directoryHint: .isDirectory)
    }

    private var scansFileURL: URL {
        baseDirectory.appending(path: "scans.json")
    }

    // MARK: - Public API

    func load() {
        try? fm.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        guard fm.fileExists(atPath: scansFileURL.path()),
              let data = try? Data(contentsOf: scansFileURL),
              var loaded = try? JSONDecoder().decode([SavedScan].self, from: data) else {
            scans = []
            return
        }

        // Reset transient states
        for i in loaded.indices {
            loaded[i].uploadStatus = loaded[i].uploadStatus.resetIfTransient
        }
        scans = loaded
        save()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(scans) else { return }
        try? data.write(to: scansFileURL, options: .atomic)
    }

    func addScan(name: String, modelURL: URL) -> UUID {
        let id = UUID()
        let scanDir = baseDirectory.appending(path: id.uuidString, directoryHint: .isDirectory)
        try? fm.createDirectory(at: scanDir, withIntermediateDirectories: true)

        // Copy model file(s)
        let destModel = scanDir.appending(path: "model.obj")
        try? fm.copyItem(at: modelURL, to: destModel)

        // Copy .mtl if present
        let mtlURL = modelURL.deletingPathExtension().appendingPathExtension("mtl")
        if fm.fileExists(atPath: mtlURL.path()) {
            let destMtl = scanDir.appending(path: mtlURL.lastPathComponent)
            try? fm.copyItem(at: mtlURL, to: destMtl)
        }

        // Generate thumbnail
        generateThumbnail(modelURL: destModel, saveAt: scanDir.appending(path: "thumbnail.jpg"))

        let scan = SavedScan(
            id: id,
            name: name,
            dateCreated: Date(),
            uploadStatus: .local
        )
        scans.append(scan)
        save()
        return id
    }

    func updateStatus(id: UUID, status: UploadStatus) {
        guard let index = scans.firstIndex(where: { $0.id == id }) else { return }
        scans[index].uploadStatus = status
        save()
    }

    func deleteScan(id: UUID) {
        scans.removeAll { $0.id == id }
        let scanDir = baseDirectory.appending(path: id.uuidString, directoryHint: .isDirectory)
        try? fm.removeItem(at: scanDir)
        save()
    }

    func modelURL(for scan: SavedScan) -> URL {
        baseDirectory.appending(path: scan.id.uuidString).appending(path: "model.obj")
    }

    func thumbnailURL(for scan: SavedScan) -> URL {
        baseDirectory.appending(path: scan.id.uuidString).appending(path: "thumbnail.jpg")
    }

    // MARK: - Thumbnail generation

    private func generateThumbnail(modelURL: URL, saveAt thumbnailURL: URL) {
        guard let scene = try? SCNScene(url: modelURL) else { return }

        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.autoenablesDefaultLighting = true

        // Frame camera to bounding box
        let (minVec, maxVec) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minVec.x + maxVec.x) / 2,
            (minVec.y + maxVec.y) / 2,
            (minVec.z + maxVec.z) / 2
        )
        let size = max(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(center.x, center.y, center.z + Float(size) * 2)
        cameraNode.look(at: center)
        scene.rootNode.addChildNode(cameraNode)
        renderer.pointOfView = cameraNode

        let image = renderer.snapshot(atTime: 0, with: CGSize(width: 200, height: 200), antialiasingMode: .multisampling4X)

        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: thumbnailURL)
        }
    }
}
