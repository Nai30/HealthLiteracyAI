import SwiftUI
import Vision

@Observable
class OCR {
    /// The array of observations to hold the request's results.
    var observations = [RecognizedTextObservation]()

    /// The Vision request.
    var request = RecognizeTextRequest()

    func performOCR(imageData: Data) async throws {
        // Clear old results
        observations.removeAll()

        // Perform the OCR request
        let results = try await request.perform(on: imageData)

        // Joshua's Edit: Save results so Camera.swift can access them
        await MainActor.run {
            self.observations = results
        }
    }
}

/// Create and dynamically size a bounding box.
struct Box: Shape {
    private let normalizedRect: NormalizedRect
    init(observation: any BoundingBoxProviding) {
        normalizedRect = observation.boundingBox
    }
    func path(in rect: CGRect) -> Path {
        let rect = normalizedRect.toImageCoordinates(rect.size, origin: .upperLeft)
        return Path(rect)
    }
}