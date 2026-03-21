import SwiftUI
import PDFKit
import Vision
import PhotosUI


// MARK: - Main Vision View
struct VisionView: View {
    @State private var scannedText: String = "Tap a button to scan a document."
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var navigateToTranslate = false
    @State private var selectedLanguage: String = "Spanish"
    let languages = ["Spanish", "French"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. Language Selection Area
                HStack {
                    Text("Target Language:")
                        .font(.subheadline)
                    Picker("Select Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // 2. Text Display Area
                ScrollView {
                    Text(scannedText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if isProcessing {
                    ProgressView("Analyzing content...")
                }

                // 3. Action Buttons
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Photo", systemImage: "photo.fill")
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }

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
            .navigationTitle("DocDigest Scanner")
            // Presentation Logic
            .fullScreenCover(isPresented: $navigateToTranslate) {
                TranslateBridge(textToTranslate: scannedText, targetLanguage: selectedLanguage)
            }
            // File Pickers & Triggers
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFilePicker(result: result)
            }
            .onChange(of: selectedItem) { oldValue, newItem in
                handlePhotoSelection(newItem: newItem)
            }
        }
    }

    // --- Logic Helpers ---
    
    func handleFilePicker(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let firstURL = urls.first { processPDF(at: firstURL) }
        case .failure(let error):
            print("File Picker Error: \(error.localizedDescription)")
        }
    }

    func handlePhotoSelection(newItem: PhotosPickerItem?) {
        Task {
            if let data = try? await newItem?.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run { isProcessing = true }
                startTextRecognition(image: image)
            }
        }
    }

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
