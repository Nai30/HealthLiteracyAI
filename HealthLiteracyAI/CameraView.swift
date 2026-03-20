import SwiftUI

struct CameraView: View {
    @State private var camera = Camera()

    var body: some View {
        ZStack {
            // Joshua added: Live camera feed so the user can see what they are scanning
            if !camera.hasPhoto {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            VStack {
                if camera.hasPhoto {
                    // Joshua added: Display the text found by the OCR logic
                    ScrollView {
                        Text(camera.recognizedText)
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
                    
                    // Joshua's Camera Icon Button: Triggers the photo and OCR chain
                    Button(action: {
                        camera.takePhotoAndProcess()
                    }) {
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
        .onAppear {
            _ = camera.setup()
        }
    }
}

// Helper to show the live camera feed in SwiftUI
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