import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Vision


struct VisionView: View {
    @State private var scannedText: String = "Select a PDF to scan."
    @State private var isProcessing: Bool = false
    @State private var showFilePicker: Bool = false

    var body: some View {
        VStack(spacing: 20) {
        
            ScrollView {
                Text(scannedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if isProcessing {
                ProgressView("Analyzing PDF...")
            }

            Button(action: { showFilePicker = true }) {
                Label("Select PDF", systemImage: "doc.badge.plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(15)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let firstURL = urls.first {
                    processPDF(at: firstURL)
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
            }
        }
    } // <-- End of Body

    // --- LOGIC SECTION: This is where 'startTextRecognition' lives! ---

    func processPDF(at url: URL) {
        isProcessing = true
        guard url.startAccessingSecurityScopedResource() else { return }
        
        defer { url.stopAccessingSecurityScopedResource() }

        if let pdfDocument = PDFDocument(url: url), let firstPage = pdfDocument.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { context in
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                firstPage.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            
            // Now we call the function below
            startTextRecognition(image: image)
        }
    }

    func startTextRecognition(image: UIImage) {
        guard let cgImage = image.cgImage else {
            self.scannedText = "Error: Invalid image data."
            self.isProcessing = false
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async { self.isProcessing = false }
                return
            }

            let fullText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            DispatchQueue.main.async {
                self.scannedText = fullText.isEmpty ? "No text found in PDF." : fullText
                self.isProcessing = false
            }
        }

        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Use a background thread so the UI doesn't freeze
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { self.isProcessing = false }
            }
        }
    }
}
