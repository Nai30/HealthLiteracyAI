//Beth created, data structure for chat messages and pre-planned questions for the chatbot for the UI
import Foundation

// Represents a single message in the UI
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool // True if from the user, false if from Gemini
}

// The 3 pre-planned questions for the user to tap
enum PreplannedQuestion: String, CaseIterable {
    case summary = "What are my main obligations in this document?"
    case deadlines = "Are there any important dates or deadlines mentioned?"
    case payments = "Does this document mention any fees or payments?"
}