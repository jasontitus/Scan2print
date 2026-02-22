import SwiftUI
import RealityKit
import _RealityKit_SwiftUI

struct ScanView: View {
    @ObservedObject var captureService: CaptureService
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            if let session = captureService.session {
                ObjectCaptureView(session: session)
                    .ignoresSafeArea()
            } else {
                ProgressView("Starting scanner...")
            }

            VStack {
                Spacer()

                if captureService.isReady {
                    Button(action: {
                        captureService.finish()
                        onFinished()
                    }) {
                        Text("Finish Scan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(.blue)
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
}
