//
//  ViewController.swift
//  HealthLiteracyAI
//
//  Created by Naima Marseille on 3/14/26.
//

import UIKit
import AVFoundation
import Vision
import SwiftUI

class ViewController: UIViewController {
    @IBOutlet weak var imgButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!
    @IBAction func pdfButtonTapped (_sender:UIButton){
        
        print("Button has been tapped")
        let alert = UIAlertController(
                title: "Ready to Scan?",
                message: "Disclaimer: DocDigest uses AI for translation and summary. Do not upload documents with sensitive information (e.g: as personal data, financial information, or legal documents.)",
                preferredStyle: .alert
            )

            // 2. Create the "Continue" Button
            let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
                // --- THIS IS WHERE YOUR NAVIGATION LIVES ---
                let swiftUIView = VisionView()
                let hostingController = UIHostingController(rootView: swiftUIView)
                
                // Push the scanner onto the stack
                self.navigationController?.pushViewController(hostingController, animated: true)
            }

            // 3. Create the "Cancel" Button
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

            // 4. Add the buttons to the alert
            alert.addAction(continueAction)
            alert.addAction(cancelAction)

            // 5. Show the alert on screen
            self.present(alert, animated: true, completion: nil)
        
        let swiftUIView = VisionView()
            
            // 2. Wrap it in a UIHostingController
            let hostingController = UIHostingController(rootView: swiftUIView)
            
            // 3. (Optional) Set a title for the back button
            hostingController.navigationItem.title = "Scanner"
            
            // 4. Push it onto your existing navigation stack
            self.navigationController?.pushViewController(hostingController, animated: true)
        }
        
    @IBAction func imgButtonTapper (_ sender: AnyObject) {
        Task{
            //when tapped it will take the user to the Camera UI
            let cameraView = CameraView()
            let hostingController = UIHostingController(rootView: cameraView)
            self.present(hostingController, animated: true)
        }
    }

    

    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // REMOVE 'func' and '()' from Task

        
    }
    
}
