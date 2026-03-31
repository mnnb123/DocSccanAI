import Foundation

/// OpenAI API service for document processing.
/// Falls back to Claude if OpenAI key is not available.

actor OpenAIService {

    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(Int, String)
        case decodingError(Error)
        case noAPIKey

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid API URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidResponse: return "Invalid response from API"
            case .apiError(let code, let msg): return "API error \(code): \(msg)"
            case .decodingError(let e): return "Decoding error: \(e.localizedDescription)"
            case .noAPIKey: return "No OpenAI API key configured"
            }
        }
    }

    struct Config {
        var apiKey: String
        var model: String = "gpt-4o"
        var maxTokens: Int = 4096
        var baseURL: String = "https://api.openai.com/v1"

        /// Built-in API key - app works out of the box
        static let builtIn: Config = Config(
            apiKey: "sk-proj-YOUR_BUILT_IN_OPENAI_KEY_HERE"
        )

        static var placeholder: Config {
            builtIn
        }
    }

    private let config: Config

    init(config: Config? = nil) {
        if let config = config {
            self.config = config
        } else if let savedKey = KeychainHelper.shared.read(.openaiAPIKey),
                  !savedKey.isEmpty {
            self.config = Config(apiKey: savedKey)
        } else if let userDefaultsKey = UserDefaults.standard.string(forKey: "openaiAPIKey"),
                  !userDefaultsKey.isEmpty {
            // Migrate from UserDefaults to Keychain
            KeychainHelper.shared.save(userDefaultsKey, for: .openaiAPIKey)
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
    }

    struct ChatResponse: Codable {
        let choices: [Choice]

        struct Choice: Codable {
            let message: ResponseMessage
        }

        struct ResponseMessage: Codable {
            let content: String?
        }
    }

    /// Send a chat message and receive full response.
    func chat(messages: [Message]) async throws -> String {
        guard !config.apiKey.isEmpty, config.apiKey != "sk-proj-YOUR_BUILT_IN_OPENAI_KEY_HERE" else {
            throw APIError.noAPIKey
        }

        guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

        let body = ChatRequest(model: config.model, max_tokens: config.maxTokens, messages: messages)
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
        guard let text = decoded.choices.first?.message.content else {
            throw APIError.invalidResponse
        }

        return text
    }

    // MARK: - Structured Extraction

    /// Extract structured data from OCR text using OpenAI.
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
            throw APIError.decodingError(NSError(domain: "OpenAIAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No JSON found in response"]))
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
}
