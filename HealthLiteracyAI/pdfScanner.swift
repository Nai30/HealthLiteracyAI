import SwiftUI
import PhotosUI
import Vision

struct VisionView: View {
    // --- Variables ---
    @State private var selectedItem: PhotosPickerItem?
    @State private var scannedText: String = "Tap the button to scan a document."
    @State private var isProcessing: Bool = false

    var body: some View {
        // We removed NavigationStack here
        VStack(spacing: 20) {
            Text("Health Literacy Scanner")
                .font(.headline)
                .padding(.top)

            ScrollView {
                Text(scannedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if isProcessing {
                ProgressView("Analyzing text...")
            }

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Select Document", systemImage: "doc.text.viewfinder")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    isProcessing = true
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        startTextRecognition(image: image)
                    } else {
                        isProcessing = false
                    }
                }
            }
            
            Spacer()
        }
        .navigationTitle("Scanner") // UIKit will use this for the top bar!
    } // End of Body

    // --- The Logic (This MUST be outside the 'body' brackets) ---
    func startTextRecognition(image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.scannedText = "Error: Could not process image data."
            self.isProcessing = false
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.scannedText = "Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var fullDetectedText = ""
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    fullDetectedText += topCandidate.string + "\n"
                }
            }
            
            DispatchQueue.main.async {
                self.scannedText = fullDetectedText.isEmpty ? "No text found." : fullDetectedText
                self.isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            self.isProcessing = false
        }
    }
}
