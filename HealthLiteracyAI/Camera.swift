/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the custom camera functionality with integrated OCR text recognition.
*/

import AVFoundation
import SwiftUI

@Observable
class Camera: NSObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var preview = AVCaptureVideoPreviewLayer()
    var output = AVCapturePhotoOutput()

    var photoData: Data? = nil
    var hasPhoto: Bool = false
    
    // Joshua added: Instance of the OCR class to handle text recognition logic
    private var ocrExecutor = OCR()
    // Joshua added: String to store the final text extracted from the image for the UI
    var recognizedText: String = ""

    /// A function that returns a Boolean value if the app has access to use the camera — `true` if the user grants access, and `false`, if not.
    func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            let status = await AVCaptureDevice.requestAccess(for: .video)
            return status
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Set up the capture session.
    func setup() -> Bool {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }

        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else {
            print("Unable to obtain video input.")
            return false
        }

        /// Check whether the session can add input.
        guard session.canAddInput(deviceInput) else {
            print("Unable to add device input to the capture session.")
            return false
        }

        /// Check whether the session can add output.
        guard session.canAddOutput(output) else {
            print("Unable to add photo output to the capture session.")
            return false
        }

        /// Add the input and output to the session.
        session.addInput(deviceInput)
        session.addOutput(output)
        session.sessionPreset = .photo

        session.commitConfiguration()

        /// Start running the capture session on a background thread.
        Task(priority: .background) {
            session.startRunning()
        }
        
        return true
    }
    
    // --- JOSHUA'S OCR WORKFLOW ---

    /// 1. Trigger the hardware to take a picture and start the processing chain
    func takePhotoAndProcess() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    /// 2. Simple getter function to return the final recognized text to other parts of the app
    func getRecognizedText() -> String {
        return recognizedText
    }

    /// 3. Delegate method: Runs automatically after the camera snaps the photo
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        // Check if image data exists
        guard let data = photo.fileDataRepresentation() else { return }
        
        self.photoData = data
        self.hasPhoto = true
        
        // Stop the live preview once the photo is captured
        self.session.stopRunning()

        // Joshua added: Immediately send the raw data to the OCR file for processing
        Task {
            do {
                try await ocrExecutor.performOCR(imageData: data)
                
                // Update the UI on the Main Thread with the joined text results
                await MainActor.run {
                    self.recognizedText = ocrExecutor.observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                }
            } catch {
                print("OCR Processing Error: \(error.localizedDescription)")
            }
        }
    }

    func retakePhoto() {
        /// Reset both the `photoData` and `hasPhoto` variables to allow photo recapture.
        photoData = nil
        hasPhoto = false
        recognizedText = "" // Also clear the old recognized text

        Task(priority: .background) {
            session.startRunning()
        }
    }
}