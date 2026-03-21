//
//  Translate.swift
//  HealthLiteracyAI
//
//  Created by Naima Marseille on 3/19/26.
//

import UIKit
class Translate: UIViewController {
    // 1. Initialize the config

    // 2. Call the function immediately to get the actual String
    lazy var gemini = GeminiHandling(apiKey: APIConfig.geminiKey)
    var incomingText: String?
    var targetLanguage: String = "Spanish"
    private var lastProcessedText: String?
    
    @IBOutlet weak var backButton: UIButton!
    @IBAction func backButtonPressed(_ sender: Any) {
        // This tells the "sheet" that was presented by CameraView to slide down and disappear
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var selectLanguage: UIButton!
    @IBAction func selectLanguagePressed(_ sender: Any) {
        guard let button = sender as? UIButton else {
                print("Error: The sender is not a button!")
                return
            }
        let spanish = UIAction(title: "Spanish") { _ in
            self.targetLanguage = "Spanish"
                    print("Language changed to Spanish")
                }
                
                let french = UIAction(title: "French") { _ in
                    self.targetLanguage = "French"
                    print("Language changed to French")
                }
                
                //// 3. Attach the menu to the "button" (not the "sender")
        button.menu = UIMenu(title: "Select Language", children: [spanish, french])
        button.showsMenuAsPrimaryAction = true
    }
    @IBOutlet weak var summarizeButton: UIButton!
    @IBAction func summarizeButtonPressed(_ sender: Any) {
        Task{
            let summary =  await gemini.summarize(targetLanguage: targetLanguage)
            await MainActor.run{
                self.textArea.text = summary
            }
      
        }
        
    }
  

    
    @IBOutlet weak var textArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textArea.text="Please Select a language to proceed with the translation"
    }
    func performGeminiTranslation(messyText: String) {
        // 1. AVOID INFINITE LOOP: If we already processed this exact text, STOP.
        print("DEBUG: Target Language is: \(targetLanguage ?? "N/A")")
        guard messyText != lastProcessedText else { return }
        lastProcessedText = messyText
        
        print("DEBUG: Received text for translation: \(messyText)")
        
        // 2. Ensure we are on the Main Thread to update the "Loading" label
        DispatchQueue.main.async {
            self.textArea.text = "Translating... please wait."
        }

        Task {
            guard isViewLoaded else {
                incomingText = messyText
                return
            }

            // Use your original gemini logic
            let success = await gemini.processDocument(rawOCRText: String(messyText))
            
            if success {
                if let translatedText = await gemini.translateFull(targetLanguage: targetLanguage) {
                    await MainActor.run {
                        self.textArea.text = translatedText
                    }
                } else {
                    await MainActor.run {
                        self.textArea.text = "Error translating, scan again."
                    }
                }
            } else {
                await MainActor.run {
                    self.textArea.text = "Gemini failed to process document."
                    print("DEBUG: Gemini processing returned success = false")
                }
            }
        }
    }
 
}
