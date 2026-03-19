//
//  ViewController.swift
//  HealthLiteracyAI
//
//  Created by Naima Marseille on 3/14/26.
//

import UIKit

class ViewController: UIViewController {
<<<<<<< Updated upstream

=======
    let camera = Camera()
    let ocrEngine = OCR()
    
>>>>>>> Stashed changes
    override func viewDidLoad() {
        super.viewDidLoad()
<<<<<<< Updated upstream
        // Do any additional setup after loading the view.
    }


=======
        
        // REMOVE 'func' and '()' from Task
        Task { @MainActor in
            let isAuthorized = await camera.checkCameraAuthorization()
            
            if isAuthorized {
                let success = camera.setup()
                
                if success {
                    // Use the session from your Camera.swift file
                    let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
                    previewLayer.frame = self.view.bounds
                    previewLayer.videoGravity = .resizeAspectFill
                    self.view.layer.insertSublayer(previewLayer, at: 0)
                    
                    print("Camera is now running!")
                }
            }
        }
    }
        @IBAction func didTapShutter(_ sender: Any) {
            camera.capturePhoto { [weak self] data in
                guard let data = data, let image = UIImage(data: data) else { return }
                
                DispatchQueue.main.async {
                    // 1. Show the photo in the review image view
                    self?.reviewImageView.image = image
                    self?.reviewImageView.isHidden = false
                    
                    // 2. Switch buttons (Hide Shutter, Show Approve/Retake)
                    self?.shutterButton.isHidden = true
                    self?.approveButton.isHidden = false
                    self?.retakeButton.isHidden = false
                    
                    // 3. Pause the live feed
                    self?.camera.session.stopRunning()
                }
            }
        }

        @IBAction func didTapRetake(_ sender: Any) {
            // Reset the UI
            reviewImageView.isHidden = true
            shutterButton.isHidden = false
            approveButton.isHidden = false
            retakeButton.isHidden = false
            
            // Restart the camera
            Task {
                self.camera.session.startRunning()
            }
        }

        @IBAction func didTapApprove(_ sender: Any) {
            guard let data = camera.photoData else { return }
            
            // NOW send it to OCR and GemLogic
            Task {
                do {
                    try await ocrEngine.performOCR(imageData: data)
                    // Here you would call your GemLogic function
                    // e.g., GemLogic.process(ocrEngine.observations)
                    print("Photo approved and sent to AI!")
                } catch {
                    print("Error processing: \(error)")
                }
            }
        }
        
        func handleOCRResults() {
            let count = ocrEngine.observations.count
            print("Analysis complete! Found \(count) text fragments.")
            
            for observation in ocrEngine.observations {
                // This gets the most likely text string for each box found
                if let topCandidate = observation.topCandidates(1).first {
                    print("Detected: \(topCandidate.string)")
                }
            }
        }
>>>>>>> Stashed changes
}

