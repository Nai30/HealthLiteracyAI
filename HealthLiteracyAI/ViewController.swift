//
//  ViewController.swift
//  HealthLiteracyAI
//
//  Created by Naima Marseille on 3/14/26.
//

import UIKit

import AVFoundation
import Vision

class ViewController: UIViewController {
    let camera = Camera()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
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
                    self.view.layer.addSublayer(previewLayer)
                    
                    print("Camera is now running!")
                }
            }
        }
    }
}
