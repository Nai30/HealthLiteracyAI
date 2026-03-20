/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the custom camera functionality with integrated OCR text recognition.
*/

import AVFoundation
import SwiftUI


@Observable
class AppCamera: NSObject, AVCapturePhotoCaptureDelegate {
    var session = AVCaptureSession()
    var output = AVCapturePhotoOutput()
    var photoData: Data? = nil
    var hasPhoto: Bool = false
    
    // Joshua's OCR Integration
    private var ocrExecutor = OCR()
    var recognizedText: String = ""

    /// Standard Camera Authorization Check
    func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    /// Sets up the lens and the output stream
    func setup() -> Bool {
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let deviceInput = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(deviceInput),
              session.canAddOutput(output) else { return false }

        session.addInput(deviceInput)
        session.addOutput(output)
        session.sessionPreset = .photo
        session.commitConfiguration()

        Task(priority: .background) { session.startRunning() }
        return true
    }

    func takePhotoAndProcess() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    /// Delegate method called by the iPhone hardware after the shutter clicks
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard let data = photo.fileDataRepresentation() else { return }
        
        self.photoData = data
        self.hasPhoto = true
        self.session.stopRunning() // Saves battery once photo is captured

        Task {
            do {
                // Calls the method we verified in TextRecognition.swift
                try await ocrExecutor.performOCR(imageData: data)
                
                await MainActor.run {
                    // Correctly maps observations to strings
                    self.recognizedText = ocrExecutor.observations.compactMap {
                        $0.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                }
            } catch {
                print("OCR Error: \(error.localizedDescription)")
            }
        }
    }

    func retakePhoto() {
        photoData = nil
        hasPhoto = false
        recognizedText = ""
        Task(priority: .background) { session.startRunning() }
    }
}
