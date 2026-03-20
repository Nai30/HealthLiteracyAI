import SwiftUI
import PDFKit
import Vision

struct TranslateBridge: UIViewControllerRepresentable {
    var textToTranslate: String

    func makeUIViewController(context: Context) -> Translate {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "TranslateVC") as! Translate
        return vc
    }

    func updateUIViewController(_ uiViewController: Translate, context: Context) {
        // This is the "Injection" step!
        uiViewController.performGeminiTranslation(messyText: textToTranslate)
    }
}
struct VisionView: View {
    // --- Variables ---
    @State private var scannedText: String = "Select a PDF to scan."
    @State private var isProcessing: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var navigateToTranslate = false
    
    let API_Key = APIConfig.geminiKey
    lazy var gemini = GeminiHandling(apiKey: API_Key)
    var body: some View {
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
                ProgressView("Analyzing PDF...")
            }

            // PDF Selection Button
            Button(action: { showFilePicker = true }) {
                Label("Select PDF", systemImage: "doc.badge.plus")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .fullScreenCover(isPresented: $navigateToTranslate) {
                // This calls our bridge and passes the scanned text
                TranslateBridge(textToTranslate: scannedText)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf], // Strictly PDFs
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
    }

    // --- Logic Section ---

    func processPDF(at url: URL) {
        isProcessing = true
        
        // PDFs from fileImporter need permission to be read
        guard url.startAccessingSecurityScopedResource() else {
            isProcessing = false
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }

        // Convert PDF Page to an Image for Vision to read
        if let pdfDocument = PDFDocument(url: url),
           let firstPage = pdfDocument.page(at: 0) {
            
            let pageRect = firstPage.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let image = renderer.image { context in
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                firstPage.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            
            startTextRecognition(image: image)
        } else {
            isProcessing = false
            scannedText = "Could not read PDF content."
        }
    }

    func startTextRecognition(image: UIImage) {
        guard let cgImage = image.cgImage else {
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
                if !fullText.isEmpty {
                        self.navigateToTranslate = true
                    }
            }
        }

        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { self.isProcessing = false }
            }
        }
    }
}
