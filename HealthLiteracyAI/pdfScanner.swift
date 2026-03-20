import SwiftUI
import PhotosUI
import Vision

struct VisionView: View {
    // --- Variables (The "State" of your app) ---
    @State private var selectedItem: PhotosPickerItem?
    @State private var scannedText: String = "Tap the button to scan a document."
    @State private var isProcessing: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. The Header
                Text("DocDigest Scanner")
                    .font(.headline)
                    .padding(.top)

                // 2. The Text Display (Scrollable for long documents)
                ScrollView {
                    Text(scannedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // 3. Loading Indicator
                if isProcessing {
                    ProgressView("Analyzing text...")
                }

                // 4. The "Ask" Button (Photos Picker)
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Select Document", systemImage: "doc.text.viewfinder")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                .onChange(of: selectedItem) { newItem in
                    // This runs when the user finishes picking a photo
                    Task {
                        isProcessing = true
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            startTextRecognition(image: image)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Vision Lead Demo")
        }
    }

    // --- The Logic (The Vision Function) ---
    func startTextRecognition(image: UIImage) {
        // Convert to CGImage (Core Graphics format)
        guard let cgImage = image.cgImage else {
            self.scannedText = "Error: Could not process image data."
            self.isProcessing = false
            return
        }
        
        // Create the Request
        let request = VNRecognizeTextRequest { request, error in
            // Handle Errors
            if let error = error {
                DispatchQueue.main.async {
                    self.scannedText = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            // Get the Results
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            // Combine all found text into one big string
            var fullDetectedText = ""
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    fullDetectedText += topCandidate.string + "\n"
                }
            }
            
            // UPDATE THE UI (Always on the Main Thread!)
            DispatchQueue.main.async {
                self.scannedText = fullDetectedText.isEmpty ? "No text found in image." : fullDetectedText
                self.isProcessing = false
            }
        }
        
        // Set Recognition Quality
        request.recognitionLevel = .accurate
        
        // Run the Request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
            self.isProcessing = false
        }
    }
}

// This allows the preview to show up in your editor
#Preview {
    VisionView()
}
