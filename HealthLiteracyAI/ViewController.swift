import UIKit
import SwiftUI

class ViewController: UIViewController {

    @IBOutlet weak var imgButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!

    @IBAction func pdfButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Ready to Scan?",
            message: "Disclaimer: DocDigest uses AI for translation. Do not upload sensitive personal data.",
            preferredStyle: .alert
        )

        let continueAction = UIAlertAction(title: "Continue", style: .default) { _ in
            let swiftUIView = VisionView()
            let hostingController = UIHostingController(rootView: swiftUIView)
            self.navigationController?.pushViewController(hostingController, animated: true)
        }

        alert.addAction(continueAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true)
    }

    @IBAction func imgButtonTapper(_ sender: AnyObject) {
        // Joshua added: Navigates to the live Camera UI
        let cameraView = CameraView() 
        let hostingController = UIHostingController(rootView: cameraView)
        
        // Present as a full-screen modal or push it onto the stack
        self.present(hostingController, animated: true)
    }
}