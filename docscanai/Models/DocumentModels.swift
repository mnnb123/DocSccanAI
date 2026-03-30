import Foundation

// MARK: - Extracted Fields (from Claude API)

/// Structured fields extracted from a document using AI.
struct ExtractedFields: Codable {
    let invoiceNumber: String?
    let dates: [String]
    let amounts: [String]
    let names: [String]
    let summary: String

    enum CodingKeys: String, CodingKey {
        case invoiceNumber = "invoice_number"
        case dates
        case amounts
        case names
        case summary
    }

    static var empty: ExtractedFields {
        ExtractedFields(invoiceNumber: nil, dates: [], amounts: [], names: [], summary: "")
    }
}

// MARK: - DocumentType Enum

enum DocumentType: String, CaseIterable {
    case invoice
    case contract
    case note
    case idCard
    case receipt
    case other
}

// MARK: - MessageRole Enum

enum MessageRole: String, CaseIterable {
    case user
    case assistant
    case system
}

// MARK: - PageReference

struct PageReference: Codable {
    let pageNumber: Int
    let excerpt: String
    let confidence: Double
}

// MARK: - View Models (non-Core Data helpers)

/// Wrapper to use Core Data objects with SwiftUI bindings.
struct DocumentWrapper: Identifiable {
    let id: UUID
    let title: String
    let pdfFileName: String
    let pageCount: Int
    let isFavorite: Bool
    let isSecured: Bool
    let isProcessed: Bool
    let fullText: String?
    let createdAt: Date
    let lastOpenedAt: Date

    init(from cd: CDDocument) {
        self.id = cd.id ?? UUID()
        self.title = cd.title ?? "Untitled"
        self.pdfFileName = cd.pdfFileName ?? ""
        self.pageCount = Int(cd.pageCount)
        self.isFavorite = cd.isFavorite
        self.isSecured = cd.isSecured
        self.isProcessed = cd.isProcessed
        self.fullText = cd.fullText
        self.createdAt = cd.createdAt ?? Date()
        self.lastOpenedAt = cd.lastOpenedAt ?? Date()
    }

    var pdfURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("PDFs").appendingPathComponent(pdfFileName)
    }
}

/// Chat message for SwiftUI (separate from Core Data).
struct ChatMessageItem: Identifiable {
    let id: UUID
    let documentId: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        documentId: UUID,
        role: MessageRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.documentId = documentId
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
