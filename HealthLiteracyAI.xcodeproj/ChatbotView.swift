//Beth created: handles the state of the messages and the thinking indicator
import SwiftUI

struct ChatbotView: View {
    // Pass your existing gemini handler in here
    var geminiHandler: GeminiHandling
    
    @State private var messages: [ChatMessage] = []
    @State private var isThinking = false

    var body: some View {
        VStack {
            // Chat History Scroll
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser { Spacer() }
                            
                            Text(message.text)
                                .padding()
                                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(message.isUser ? .white : .primary)
                                .cornerRadius(16)
                                .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                            
                            if !message.isUser { Spacer() }
                        }
                    }
                    if isThinking {
                        ProgressView()
                            .padding()
                    }
                }
                .padding()
            }
            
            // Pre-planned Question Buttons
            VStack(spacing: 8) {
                Text("Ask a question about your document:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(PreplannedQuestion.allCases, id: \.self) { question in
                    Button(action: {
                        Task {
                            await submitQuestion(text: question.rawValue)
                        }
                    }) {
                        Text(question.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                    }
                    .disabled(isThinking)
                }
            }
            .padding(.horizontal)
            
            // Critical Disclaimer (Required for guardrails)
            Text(" DocDigest uses AI-generated responses. This is not legal advice. Always consult a professional for legal matters.")
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .navigationTitle("DocDigest Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Logic to handle tapping a button
    private func submitQuestion(text: String) async {
        // Add user message to UI
        messages.append(ChatMessage(text: text, isUser: true))
        isThinking = true
        
        // Ask Gemini
        if let response = await geminiHandler.askQuestion(userQuestion: text) {
            messages.append(ChatMessage(text: response, isUser: false))
        } else {
            messages.append(ChatMessage(text: "Sorry, I ran into an error processing that.", isUser: false))
        }
        
        isThinking = false
    }
}