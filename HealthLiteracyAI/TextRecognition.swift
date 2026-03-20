import SwiftUI
import Vision

@Observable
class OCR {
    /// Joshua's Edit: Array of observations using the correct Vision 17+ type
    var observations = [RecognizeTextRequest.Observation]()

    /// The Vision request object
    var request = RecognizeTextRequest()

    /// Function to process image data and extract text
    func performOCR(imageData: Data) async throws {
        // 1. Clear old results for a fresh scan
        observations.removeAll()

        // 2. Perform the request (This is an async call)
        let results = try await request.perform(on: imageData)

        // 3. Update the observations on the Main Thread for UI safety
        await MainActor.run {
            self.observations = results
        }
    }
}

/// Joshua added: Bounding box logic to potentially highlight text on screen
struct Box: Shape {
    private let normalizedRect: CGRect 

    init(observation: RecognizeTextRequest.Observation) {
        self.normalizedRect = observation.boundingBox
    }

    func path(in rect: CGRect) -> Path {
        // Converts the 0.0-1.0 coordinates from Vision into actual screen pixels
        let projectRect = VNImageRectForNormalizedRect(normalizedRect, Int(rect.width), Int(rect.height))
        
        // Flips the coordinate system so boxes appear in the right spot
        let transformedRect = CGRect(x: projectRect.minX, 
                                     y: rect.height - projectRect.maxY, 
                                     width: projectRect.width, 
                                     height: projectRect.height)
        
        return Path(transformedRect)
    }
}