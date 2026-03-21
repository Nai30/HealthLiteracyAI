import SwiftUI
import UIKit

struct TranslateBridge: UIViewControllerRepresentable {
    // These variables receive the data from your SwiftUI CameraView
    var textToTranslate: String
    var targetLanguage: String

    // This function creates the Storyboard view for the first time
    func makeUIViewController(context: Context) -> Translate {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // CRITICAL: Ensure "DocDigestVC" is set in your Storyboard Identity Inspector!
        let vc = storyboard.instantiateViewController(withIdentifier: "DocDigestVC") as! Translate
        return vc
    }

    // This function pushes new data into the View Controller whenever it changes
    func updateUIViewController(_ uiViewController: Translate, context: Context) {
        uiViewController.targetLanguage = targetLanguage
        
        // This triggers your Gemini logic in Translate.swift
        if !textToTranslate.isEmpty {
            uiViewController.performGeminiTranslation(messyText: textToTranslate)
        }
    }
}
