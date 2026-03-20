// Created by Gabriella Small on 3/17/2026, based off of Bethany's "gemlogic.py" code
//Beth added AskQuestion method and SendChatRequest method, and added the chat history array to store the conversation history for better context in the chatbot, networking specific for chatbot
import Foundation
import FoundationNetworking 

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
    //-----------STEP 1: PROCESSING --------
    // (not returned back to UI)
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

    // -------- STEP 2: TRANSLATING------ 
    // (is sent back to UI)
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

    // ------- STEP 3: SUMMARIZING------- 
    // (is sent back to UI)
    // Triggers Instruction A from System Instructions within API to process translatedText
    func summarize(targetLanguage : String) async -> String? {
        guard let translatedText = self.translatedText else{
            return "Error: There is no translation that can be summarized."
        }
        let prompt = "Use !ONLY! Instruction B to process \(translatedText) in this language: \(targetLanguage)"
        return await sendRequest(userPrompt: prompt)
    }

// --- STEP 4: THE CHATBOT ---
    /// Entry point for the SwiftUI ChatbotView
    func askQuestion(userQuestion: String) async -> String? {
        // 1. Prime the AI with the document context if this is a fresh chat
        if chatHistory.isEmpty {
            // Priority: Use translated text if available, otherwise raw JSON, otherwise fallback
            let contextText = translatedText ?? processedJSON ?? "No document provided."
            let primingMessage = "Here is the document context you must answer questions about: \(contextText)"
            
            chatHistory.append(["role": "user", "parts": [["text": primingMessage]])
            chatHistory.append(["role": "model", "parts": [["text": "Understood. I will answer questions based strictly on this document context."]]])
        }
        
        // 2. Add the user's specific question to history
        chatHistory.append(["role": "user", "parts": [["text": userQuestion]]])
         
        // 3. Request response from Gemini with full history
        if let response = await sendChatRequest() {
            // Append the AI's response to history so the next question has context
            chatHistory.append(["role": "model","parts": [["text": response]]])
            return response
        }
        return nil
    }

        //-------- NETWORK LOGIC --------
        /// Standard request for single-shot tasks (Translation/Summary)
    /* sendRequest function - converts Swift object into json data, then into a network request. That network request gives
    us back formatted JSON data that is then turned into a swift string that we will return back to the user */
    private func sendRequest(userPrompt: String) async -> String? {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else { 
            return nil  }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = ["contents": [["role": "user", "parts": [["text": userPrompt]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        return await performNetworkCall(with: request)
    }

/// Specialized request for Chatbot (Handles History, Temperature, and System Guardrails)
    private func sendChatRequest() async -> String? {
        guard let url = URL(string: "\(endpoint)?key=\(apiKey)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Payload including System Instructions and low Temperature
        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": "You are a helpful document assistant for DocDigest. You explain legal terms in plain language based ONLY on the provided text. You are NOT a lawyer. If a user asks for legal advice or a 'loophole,' politely explain that you can only summarize the text provided and they should consult a professional."]]
            ],
            "contents": chatHistory,
            "generationConfig": [
                "temperature": 0.1 // Keeps responses factual and grounded in the text
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        return await performNetworkCall(with: request)
    }

    /// Helper to handle the actual URLSession and JSON parsing
    private func performNetworkCall(with request: URLRequest) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let candidates = json["candidates"] as? [[String: Any]],
                let first = candidates.first,
                let content = first["content"] as? [AnyHashable: Any],
                let parts = content["parts"] as? [[AnyHashable: Any]],
                let text = parts.first?["text"] as? String {
                    return text
                }
        } catch {
            print("DocDigest Network Error: \(error.localizedDescription)")
        }
        return nil
    }
// Reset memory for each new session
    func reset() {
        self.processedJSON = nil
        self.translatedText = nil
        self.chatHistory.removeAll()
    }    
}