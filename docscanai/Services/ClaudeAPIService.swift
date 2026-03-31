import Foundation

/// Claude API service using Anthropic's REST API.
/// Supports streaming responses and structured JSON extraction.

actor ClaudeAPIService {

    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(Int, String)
        case decodingError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidResponse: return "Invalid response from API"
            case .apiError(let code, let msg): return "API error \(code): \(msg)"
            case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
            }
        }
    }

    struct Config {
        var apiKey: String
        var model: String = "claude-opus-4-5-20261120"
        var maxTokens: Int = 4096
        var baseURL: String = "https://api.anthropic.com/v1"

        /// Built-in API key - app works out of the box
        /// User can override in Settings > API Key
        static let builtIn: Config = Config(
            apiKey: "sk-ant-api03-YOUR_BUILT_IN_API_KEY_HERE"
        )

        static var placeholder: Config {
            builtIn
        }
    }

    private let config: Config

    init(config: Config? = nil) {
        if let config = config {
            self.config = config
        } else if let savedKey = KeychainHelper.shared.read(.claudeAPIKey),
                  !savedKey.isEmpty {
            self.config = Config(apiKey: savedKey)
        } else if let userDefaultsKey = UserDefaults.standard.string(forKey: "claudeAPIKey"),
                  !userDefaultsKey.isEmpty {
            // Migrate from UserDefaults to Keychain
            KeychainHelper.shared.save(userDefaultsKey, for: .claudeAPIKey)
            self.config = Config(apiKey: userDefaultsKey)
        } else {
            self.config = Config.builtIn
        }
    }

    // MARK: - Chat Completion

    struct Message: Codable, Sendable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let max_tokens: Int
        let messages: [Message]
        let stream: Bool
    }

    struct ChatResponse: Codable {
        let content: [ContentBlock]
        let usage: Usage

        struct ContentBlock: Codable {
            let type: String
            let text: String?
        }

        struct Usage: Codable {
            let input_tokens: Int
            let output_tokens: Int
        }
    }

    /// Send a chat message and receive a streaming async sequence.
    func streamChat(messages: [Message]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let text = try await chat(messages: messages)
                    for char in text {
                        continuation.yield(String(char))
                        try await Task.sleep(nanoseconds: 10_000_000)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Send a chat message and receive full response.
    func chat(messages: [Message]) async throws -> String {
        guard let url = URL(string: "\(config.baseURL)/messages") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "anthropic-version")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body = ChatRequest(model: config.model, max_tokens: config.maxTokens, messages: messages, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let bodyStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.apiError(httpResponse.statusCode, bodyStr)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let textBlock = decoded.content.first(where: { $0.type == "text" }),
              let text = textBlock.text else {
            throw APIError.invalidResponse
        }

        return text
    }

    // MARK: - Structured Extraction

    /// Extract structured data from OCR text using Claude.
    func extractStructuredData(ocrText: String) async throws -> ExtractedFields {
        let systemPrompt = """
        Bạn là trợ lý AI chuyên trích xuất dữ liệu từ tài liệu.
        Phân tích văn bản OCR được cung cấp và trích xuất các trường có cấu trúc.
        Trả về JSON với các trường: invoice_number, dates, amounts, names, summary.
        Nếu không tìm thấy trường nào, trả về chuỗi rỗng hoặc mảng rỗng.
        Chỉ trả về JSON, không giải thích gì thêm.
        """

        let userMessage = Message(role: "user", content: "Văn bản OCR:\n\(String(ocrText.prefix(3000)))")
        let result = try await chat(messages: [
            Message(role: "system", content: systemPrompt),
            userMessage
        ])

        guard let jsonStart = result.firstIndex(of: "{"),
              let jsonEnd = result.lastIndex(of: "}") else {
            throw APIError.decodingError(NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No JSON found in response"]))
        }

        let jsonString = String(result[jsonStart...jsonEnd])
        return try JSONDecoder().decode(ExtractedFields.self, from: Data(jsonString.utf8))
    }

    // MARK: - Summarize

    func summarize(text: String, maxPoints: Int = 5) async throws -> String {
        let systemPrompt = """
        Bạn là trợ lý AI tóm tắt tài liệu. Tóm tắt văn bản dưới đây thành \(maxPoints) điểm chính.
        Trả về danh sách bullet points bằng tiếng Việt.
        """

        let userMessage = Message(role: "user", content: "Nội dung:\n\(text.prefix(4000))")
        return try await chat(messages: [
            Message(role: "system", content: systemPrompt),
            userMessage
        ])
    }

    // MARK: - Translate

    enum TranslationLanguage: String {
        case vietnamese = "Vietnamese"
        case english = "English"
        case chinese = "Chinese"
    }

    func translate(text: String, from: TranslationLanguage, to: TranslationLanguage) async throws -> String {
        let systemPrompt = """
        Bạn là trợ lý dịch thuật. Dịch văn bản từ \(from.rawValue) sang \(to.rawValue).
        Chỉ trả về bản dịch, không giải thích.
        """

        let userMessage = Message(role: "user", content: String(text.prefix(3000)))
        return try await chat(messages: [
            Message(role: "system", content: systemPrompt),
            userMessage
        ])
    }

    // MARK: - Flashcard Generation

    struct Flashcard: Codable {
        let question: String
        let answer: String
        let pageRef: Int?

        enum CodingKeys: String, CodingKey {
            case question, answer
            case pageRef = "page_ref"
        }
    }

    func generateFlashcards(text: String, count: Int = 10) async throws -> [Flashcard] {
        let systemPrompt = """
        Tạo \(count) flashcards từ nội dung tài liệu dưới đây.
        Trả về JSON array với cấu trúc: [{\"question\": \"...\", \"answer\": \"...\", \"page_ref\": 1}]
        Mỗi flashcard nên hỏi về một điểm quan trọng trong tài liệu.
        """

        let userMessage = Message(role: "user", content: "Nội dung:\n\(text.prefix(3000))")
        let result = try await chat(messages: [
            Message(role: "system", content: systemPrompt),
            userMessage
        ])

        guard let jsonStart = result.firstIndex(of: "["),
              let jsonEnd = result.lastIndex(of: "]") else {
            throw APIError.decodingError(NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No JSON array found"]))
        }

        let jsonString = String(result[jsonStart...jsonEnd])
        return try JSONDecoder().decode([Flashcard].self, from: Data(jsonString.utf8))
    }
}
