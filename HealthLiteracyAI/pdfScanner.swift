import SwiftUI
import PDFKit
import Vision
import PhotosUI

// MARK: - Translate Bridge
struct TranslateBridge: UIViewControllerRepresentable {
    var textToTranslate: String

        // 1. This CREATES the view (Runs once)
        func makeUIViewController(context: Context) -> Translate {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // CRITICAL: Make sure this ID matches the one we set in the Identity Inspector!
            let vc = storyboard.instantiateViewController(withIdentifier: "DocDigestVC") as! Translate
            return vc
        }

        // 2. This UPDATES the view (Runs whenever 'textToTranslate' changes)
        func updateUIViewController(_ uiViewController: Translate, context: Context) {
            // PUSH the scanned text into your Storyboard ViewController's function
            uiViewController.performGeminiTranslation(messyText: textToTranslate)
        }
}

// MARK: - Main Vision View
struct VisionView: View {
    // --- State Variables ---
    @State private var scannedText: String = "Tap a button to scan a document."
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var navigateToTranslate = false
    @State private var selectedLanguage: String = "Spanish" // Default
    let languages = ["Spanish", "French", "German", "Chinese", "Hindi"]

    var body: some View {
        NavigationStack {
            ForEach(languages, id: \.self) { lang in
                    Text(lang)
                }
            }
            .pickerStyle(.menu)
            .padding()
        
            VStack(spacing: 20) {
                Text("DocDigest Scanner")
                    .font(.headline)
                    .padding(.top)

                // Text Display Area
                ScrollView {
                    Text(scannedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if isProcessing {
                    ProgressView("Analyzing content...")
                }

                HStack(spacing: 20) {
                    // Photo Selection
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Photo", systemImage: "photo.fill")
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

                    // PDF Selection
                    Button(action: { showFilePicker = true }) {
                        Label("PDF", systemImage: "doc.badge.plus")
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
            .navigationTitle("Vision Lead")
            // Navigation to the Translate Screen
            .fullScreenCover(isPresented: $navigateToTranslate) {
                TranslateBridge(textToTranslate: scannedText)
            }
            // PDF Picker Logic
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
                    print("File Picker Error: \(error.localizedDescription)")
                }
            }
            // Photo Picker Logic
   
            // Photo Picker Logic (iOS 17+ Style)
            .onChange(of: selectedItem) { oldValue, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // We use await MainActor.run to update the UI state safely
                        await MainActor.run { isProcessing = true }
                        startTextRecognition(image: image)
                    }
                }
            }
        }
    }

    // --- Logic: PDF Processing ---
    func processPDF(at url: URL) {
        isProcessing = true
        
        guard url.startAccessingSecurityScopedResource() else {
            isProcessing = false
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }

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
            scannedText = "Could not read PDF."
        }
    }

    // --- Logic: Vision Text Recognition ---
    func startTextRecognition(image: UIImage) {
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async { self.isProcessing = false }
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: "\n")

            DispatchQueue.main.async {
                self.scannedText = fullText.isEmpty ? "No text found." : fullText
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

#Preview {
    VisionView()
}
