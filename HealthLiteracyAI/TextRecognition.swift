import SwiftUI
import Vision

@Observable
class OCR {
    /// Joshua's Edit: Use the correct Vision Observation type
    var observations = [RecognizeTextRequest.Observation]()

    /// The Vision request for text recognition
    var request = RecognizeTextRequest()

    func performOCR(imageData: Data) async throws {
        // Clear old results for a clean scan
        observations.removeAll()

        // Perform the OCR request on the captured image data
        let results = try await request.perform(on: imageData)

        // Joshua's Edit: Save results to the Main thread so the UI updates instantly
        await MainActor.run {
            self.observations = results
        }
    }
}

/// Joshua added: Create and dynamically size a bounding box based on Vision results
struct Box: Shape {
    private let normalizedRect: CGRect // Vision uses CGRect for bounding boxes

    init(observation: RecognizeTextRequest.Observation) {
        self.normalizedRect = observation.boundingBox
    }

    func path(in rect: CGRect) -> Path {
        // Convert normalized coordinates (0 to 1) to the actual view size
        let projectRect = VNImageRectForNormalizedRect(normalizedRect, Int(rect.width), Int(rect.height))
        
        // Adjust for the coordinate system (Vision is bottom-up, UIKit is top-down)
        let transformedRect = CGRect(x: projectRect.minX, 
                                     y: rect.height - projectRect.maxY, 
                                     width: projectRect.width, 
                                     height: projectRect.height)
        
        return Path(transformedRect)
    }
}