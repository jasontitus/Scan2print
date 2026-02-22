import SwiftUI
import SceneKit

struct ModelPreviewView: UIViewRepresentable {
    let modelURL: URL

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = .systemBackground

        if let scene = try? SCNScene(url: modelURL) {
            scnView.scene = scene
            frameCamera(in: scene, view: scnView)
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func frameCamera(in scene: SCNScene, view: SCNView) {
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
        view.pointOfView = cameraNode
    }
}
