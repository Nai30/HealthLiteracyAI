// Created by Gabriella Small on 3/17/2026, based off of Bethany's "gemlogic.py" code
// Beth added AskQuestion method and SendChatRequest method, and added the chat history array
// for better context in the chatbot, networking specific for chatbot

import Foundation

class GeminiHandling {
    // Private Variables: handles API Key, gemini version type, processed JSON text, and translated text within class
    private let apiKey: String
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    private var processedJSON: String?
    private var translatedText: String?
    private var chatHistory: [[String: Any]] = []

    // Key injected into class during initialization
    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // ----------- STEP 1: PROCESSING --------
    // Process Raw Data into Categorized JSON
    func processDocument(rawOCRText: String) async -> Bool {
        let prompt = "Use !ONLY! System Instruction BASE and then clean and categorize this messy OCR text into a structured JSON format: \(rawOCRText)"
        if let result = await sendRequest(userPrompt: prompt) {
            self.processedJSON = result
            return true
        }
        return false
    }

    // -------- STEP 2: TRANSLATING ------
    func translateFull(targetLanguage: String) async -> String? {
        guard let jsonData = self.processedJSON else {
            return "Error: There is no data to translate."
        }
        let prompt = "Use !ONLY! Instruction A to process the following JSON file \(jsonData) in the following target language: \(targetLanguage)"

        if let result = await sendRequest(userPrompt: prompt) {
            self.translatedText = result
            return result
        }
        return nil
    }

    // ------- STEP 3: SUMMARIZING -------
    func summarize(targetLanguage: String) async -> String? {
        guard let translatedText = self.translatedText else {
            return "Error: There is no translation that can be summarized."
        }
        let prompt = "Use !ONLY! Instruction B to process \(translatedText) in this language: \(targetLanguage)"
        return await sendRequest(userPrompt: prompt)
    }

    // --- STEP 4: THE CHATBOT ---
    func askQuestion(userQuestion: String) async -> String? {
        if chatHistory.isEmpty {
            let contextText = translatedText ?? processedJSON ?? "No document provided."
            let primingMessage = "Here is the document context you must answer questions about: \(contextText)"
            
            chatHistory.append(["role": "user", "parts": [["text": primingMessage]]])
            chatHistory.append(["role": "model", "parts": [["text": "Understood. I will answer questions based strictly on this document context."]]])
        }
        
        chatHistory.append(["role": "user", "parts": [["text": userQuestion]]])
         
        if let response = await sendChatRequest() {
            chatHistory.append(["role": "model", "parts": [["text": response]]])
            return response
        }
        return nil
    }

    // -------- NETWORK LOGIC --------
    private func sendRequest(userPrompt: String) async -> String? {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["contents": [["role": "user", "parts": [["text": userPrompt]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        return await performNetworkCall(with: request)
    }

    private func sendChatRequest() async -> String? {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": "You are a helpful document assistant for DocDigest. You explain legal terms in plain language based ONLY on the provided text. You are NOT a lawyer. If a user asks for legal advice or a 'loophole,' politely explain that you can only summarize the text provided and they should consult a professional."]]
            ],
            "contents": chatHistory,
            "generationConfig": [
                "temperature": 0.1
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        return await performNetworkCall(with: request)
    }

    private func performNetworkCall(with request: URLRequest) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let first = candidates.first,
               let content = first["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                    return text
                }
        } catch {
            print("DocDigest Network Error: \(error.localizedDescription)")
        }
        return nil
    }
}
