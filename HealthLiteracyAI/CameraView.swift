import SwiftUI

struct CameraView: View {
    @State private var camera = Camera()

    var body: some View {
        ZStack {
            // Fix for the Black Screen: Shows live feed from the camera session
            if !camera.hasPhoto {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                if camera.hasPhoto {
                    // UI to display the recognized text results
                    ScrollView {
                        Text(camera.recognizedText.isEmpty ? "No text detected." : camera.recognizedText)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                    }
                    .padding()
                    
                    Button("Scan New Document") {
                        camera.retakePhoto()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 30)
                } else {
                    Spacer()
                    // Joshua's Camera Icon Button
                    Button(action: { camera.takePhotoAndProcess() }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 85, height: 85)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear { _ = camera.setup() }
    }
}

/// Helper struct that translates UIKit's preview layer into SwiftUI
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}