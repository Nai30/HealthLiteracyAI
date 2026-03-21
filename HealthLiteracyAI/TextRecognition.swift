import SwiftUI
import Vision

@Observable
class OCR {
    var observations: [VNRecognizedTextObservation] = []

    func performOCR(imageData: Data) async throws {
        await MainActor.run {
            self.observations.removeAll()
        }

        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest()
        
        let handler = VNImageRequestHandler(cgImage: cgImage)

        try handler.perform([request])

        let results = request.results ?? []

        await MainActor.run {
            self.observations = results
        }
    }
}
struct Box: Shape {
    let normalizedRect: CGRect

    init(observation: VNRecognizedTextObservation) {
        normalizedRect = observation.boundingBox
    }

    func path(in rect: CGRect) -> Path {
        let projected = VNImageRectForNormalizedRect(
            normalizedRect,
            Int(rect.width),
            Int(rect.height)
        )

        let flipped = CGRect(
            x: projected.minX,
            y: rect.height - projected.maxY,
            width: projected.width,
            height: projected.height
        )

        return Path(flipped)
    }
}
