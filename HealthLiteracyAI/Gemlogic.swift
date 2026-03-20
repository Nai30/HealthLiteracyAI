// Created by Gabriella Small on 3/17/2026, based off of Bethany's "gemlogic.py" code
import Foundation


class GeminiHandling {
    // Private Variables: handles API Key, gemini version type, processed JSON text, and translated text within class
    private let apiKey: String
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    private var processedJSON: String?
    private var translatedText: String?

    // Key injected into class during initialization
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // Step 1, the processing (not returned back to UI)
    // Process Raw Data into Categorized JSON (this makes it easier for Gemini to process for the functions)
    // Triggered by the Camera/PDF buttons that generate messy OCR text
    func processDocument(rawOCRText: String) async -> Bool {
        // Prompt Gemini to take messy OCR text and return a clean, categorized JSON
        let prompt = "Use !ONLY! System Instruction BASE and then clean and categorize this messy OCR text into a structured JSON format: \(rawOCRText)"
        
        if let result = await sendRequest(userPrompt: prompt) {
            self.processedJSON = result
            return true
        }
        return false
    }

    // Step 2: the translating (is sent back to UI)
    /* Triggers Instruction A from System Instructions, which already has a prompt to handle translating
    a document in full with fully formatted text that is easy to read*/
    func translateFull(targetLanguage: String) async -> String? {
        //handles if translateFull is called but not given any data to translate
        guard let jsonData = self.processedJSON else {
            return "Error: There is no data to translate."
        }
        //prompt that is given to gemini
        let prompt = "Use !ONLY! Instruction A to process the following JSON file \(jsonData) in the following target language: \(targetLanguage)"

        //Send prompt to API, if processed then get result, if not processed then return null
        if let result = await sendRequest(userPrompt: prompt) {
            self.translatedText = result
            return result
        }
        return nil
    }

    // Step 3: the summarizing (is sent back to UI)
    // Triggers Instruction A from System Instructions within API to process translatedText
    func summarize(targetLanguage : String) async -> String? {
        guard let translatedText = self.translatedText else{
            return "Error: There is no translation that can be summarized."
        }

        let prompt = "Use !ONLY! Instruction B to process \(translatedText) in this language: \(targetLanguage)"
        return await sendRequest(userPrompt: prompt)
    }

    // Reset memory for each new session, so gemini doesn't hold old info
    func reset(){
        self.processedJSON = nil
        self.translatedText = nil
    }

    /* sendRequest function - converts Swift object into json data, then into a network request. That network request gives
    us back formatted JSON data that is then turned into a swift string that we will return back to the user */
    private func sendRequest(userPrompt: String) async -> String? {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents" : [
                ["role": "user", "parts": [["text": userPrompt]]]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as?[String: Any],
                let candidates = json["candidates"] as? [[String: Any]],
                let first = candidates.first,
                let content = first["content"] as? [AnyHashable: Any],
                let parts = content["parts"] as? [[AnyHashable: Any]],
                let text = parts.first?["text"] as? String {
                    return text
                }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        return nil
        

    }





}
