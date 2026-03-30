import Foundation

// MARK: - OCR Result Types

/// Result from OCR text recognition.
struct OCRResult: Sendable {
    let fullText: String
    let textBlocks: [TextBlock]

    struct TextBlock: Sendable {
        let text: String
        let boundingBox: CGRect
        let confidence: Float
        let pageNumber: Int
    }
}