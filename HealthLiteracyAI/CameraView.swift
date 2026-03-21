import SwiftUI
import AVFoundation

struct CameraView: View {
    @State private var camera = AppCamera()
    // We don't need the extra 'recognizedText' variable here anymore
    // because we can pull directly from 'camera.recognizedText'
    @State private var isShowingTranslate = false
    @State private var targetLang = "Spanish"

    var body: some View {
        ZStack {
            // Live Feed
            if !camera.hasPhoto {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
             VStack {
                if camera.hasPhoto {
                    // 1. Show the ScrollView with the OCR results
                    ScrollView {
                        Text(camera.recognizedText.isEmpty ? "No text detected." : camera.recognizedText)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                    }
                    .padding()

                    // 2. INSERT THE TRANSLATE BUTTON HERE
                    // It only shows up when there's a photo and text to process
                    Button(action: {
                        if !camera.recognizedText.isEmpty {
                            isShowingTranslate = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Translate with Gemini")
                        }
                        .bold()
                        .frame(width: 280, height: 50)
                        .background(camera.recognizedText.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 10)

                    // 3. Keep your "Retake" button below it
                    Button("Scan New Document") {
                        camera.retakePhoto()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .padding(.bottom, 30)

                } else {
                    Spacer()
                    // Capture Button (Joshua's Icon)
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
            // 4. ATTACH THE SHEET TO THE VSTACK (OUTSIDE THE IF/ELSE)
            .sheet(isPresented: $isShowingTranslate) {
                TranslateBridge(
                    textToTranslate: camera.recognizedText,
                    targetLanguage: targetLang
                )
            }
        }
        .onAppear { _ = camera.setup() }
        // 4. The Sheet Trigger
        // Use camera.recognizedText so the Bridge gets the actual OCR data
        .sheet(isPresented: $isShowingTranslate) {
            TranslateBridge(textToTranslate: camera.recognizedText, targetLanguage: targetLang)
        }
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
