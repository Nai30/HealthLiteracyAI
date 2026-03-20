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
    //Will change this to be connected to whatever button item is shown

    
    @IBOutlet weak var textArea: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textArea.text = "Awaiting translation..."
        if let text = incomingText{
            self.textArea.text = text
            performGeminiTranslation(messyText: text)
        }
    }
    func performGeminiTranslation(messyText: String){
        Task{
            // If the view isn't loaded yet, just save the text for later
                    guard isViewLoaded else {
                        incomingText = messyText
                        return
                    }
            //wait for gemini to process the text
            let success = await gemini.processDocument(rawOCRText: String(messyText))
            if success{
                
                //get translated text
                if let translatedText = await gemini.translateFull(targetLanguage: targetLanguage){
                    await MainActor.run{
                        self.textArea.text = translatedText
                    }
                    //get the translatedText into text area
                    
                    
                }else{
                    await MainActor.run{
                        self.textArea.text = "Error translating, scan again."
                    }
                }
            }
        }
    }
 
}
