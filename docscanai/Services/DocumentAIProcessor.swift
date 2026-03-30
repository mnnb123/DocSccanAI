import Foundation
import Vision
import VisionKit
import PDFKit
import UIKit

/// Orchestrates the full AI document processing pipeline:
/// 1. OCR (Vision on-device)
/// 2. Structured extraction (Claude API)
/// 3. Table detection (Vision)
/// 4. Field extraction (Claude API)

actor DocumentAIProcessor {

    enum ProcessingError: Error, LocalizedError {
        case emptyImages
        case pdfLoadFailed
        case ocrFailed(Error)
        case claudeFailed(Error)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .emptyImages: return "No images to process"
            case .pdfLoadFailed: return "Failed to load PDF"
            case .ocrFailed(let e): return "OCR failed: \(e.localizedDescription)"
            case .claudeFailed(let e): return "AI processing failed: \(e.localizedDescription)"
            case .cancelled: return "Processing was cancelled"
            }
        }
    }

    // MARK: - Processing State

    struct ProcessingState {
        var phase: Phase
        var progress: Double
        var currentPage: Int
        var totalPages: Int

        enum Phase: String {
            case extracting = "Đang trích xuất văn bản..."
            case analyzing = "Đang phân tích AI..."
            case extractingFields = "Đang trích xuất dữ liệu..."
            case detectingTables = "Đang nhận diện bảng..."
            case done = "Hoàn thành"
        }
    }

    /// Callback for progress updates (runs on MainActor).
    typealias ProgressHandler = @MainActor (ProcessingState) -> Void

    // MARK: - API Key Management

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
    }

    private var claudeService: ClaudeAPIService?

    private func getClaudeService() -> ClaudeAPIService {
        if claudeService == nil {
            let key = apiKey
            if !key.isEmpty {
                claudeService = ClaudeAPIService(config: .init(apiKey: key))
            } else {
                claudeService = ClaudeAPIService()
            }
        }
        return claudeService!
    }

    // MARK: - Full Pipeline: Images → OCR + Claude Extraction

    /// Process images through full OCR + AI extraction pipeline.
    func processImages(_ images: [UIImage], onProgress: ProgressHandler?) async throws -> ProcessingResult {
        guard !images.isEmpty else { throw ProcessingError.emptyImages }

        await onProgress?(ProcessingState(phase: .extracting, progress: 0, currentPage: 0, totalPages: images.count))

        // Step 1: OCR each image
        var ocrResults: [OCRResult] = []
        let ocrService = OCRService()

        for (index, image) in images.enumerated() {
            let result = try await ocrService.recognizeText(from: image, pageNumber: index + 1)
            ocrResults.append(result)

            await onProgress?(ProcessingState(
                phase: .extracting,
                progress: Double(index + 1) / Double(images.count) * 0.4,
                currentPage: index + 1,
                totalPages: images.count
            ))
        }

        // Combine all OCR text
        let fullText = ocrResults.map { $0.fullText }.joined(separator: "\n\n")
        let textBlocks = ocrResults.flatMap { $0.textBlocks }

        // Step 2: Table detection (Vision)
        await onProgress?(ProcessingState(phase: .detectingTables, progress: 0.5, currentPage: 0, totalPages: images.count))
        let tables = try await detectTables(in: images)

        await onProgress?(ProcessingState(phase: .analyzing, progress: 0.6, currentPage: 0, totalPages: images.count))

        // Step 3: Claude structured extraction
        guard !apiKey.isEmpty else {
            // No API key — return OCR-only result
            return ProcessingResult(
                fullText: fullText,
                textBlocks: textBlocks,
                tables: tables,
                extractedFields: nil,
                summary: nil,
                pageCount: images.count
            )
        }

        let extractedFields = try await extractStructuredFields(from: fullText, onProgress: onProgress)
        let summary = try await generateSummary(from: fullText, onProgress: onProgress)

        await onProgress?(ProcessingState(phase: .done, progress: 1.0, currentPage: images.count, totalPages: images.count))

        return ProcessingResult(
            fullText: fullText,
            textBlocks: textBlocks,
            tables: tables,
            extractedFields: extractedFields,
            summary: summary,
            pageCount: images.count
        )
    }

    // MARK: - Full Pipeline: PDF URL → Processing Result

    /// Process a PDF file (render pages → process).
    func processPDF(at url: URL, onProgress: ProgressHandler?) async throws -> ProcessingResult {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw ProcessingError.pdfLoadFailed
        }

        var images: [UIImage] = []
        let pageCount = pdfDocument.pageCount

        for i in 0..<pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let image = page.thumbnail(of: CGSize(width: 1200, height: 1600), for: .mediaBox)
            if image.size.width > 0 && image.size.height > 0 {
                images.append(image)
            }

            await onProgress?(ProcessingState(
                phase: .extracting,
                progress: Double(i + 1) / Double(pageCount) * 0.3,
                currentPage: i + 1,
                totalPages: pageCount
            ))
        }

        return try await processImages(images, onProgress: onProgress)
    }

    // MARK: - Table Detection

    /// Detect tables in images using Vision framework.
    /// Note: VNRecognizeTableRequest requires iOS 17+. Falls back to empty tables on iOS 16.
    func detectTables(in images: [UIImage]) async throws -> [TableData] {
        var tables: [TableData] = []

        // VNRecognizeTableRequest is available only on iOS 17+
        // Fallback: use OCR text blocks to detect table-like patterns
        for (index, image) in images.enumerated() {
            let ocrResult = try await OCRService().recognizeText(from: image, pageNumber: index + 1)

            // Simple table detection: rows with similar Y coordinates + aligned X coordinates
            let detectedTables = detectTablesFromTextBlocks(ocrResult.textBlocks, pageNumber: index + 1)
            tables.append(contentsOf: detectedTables)
        }

        return tables
    }

    /// Detect table structures from OCR text blocks using alignment heuristics.
    private func detectTablesFromTextBlocks(_ blocks: [OCRResult.TextBlock], pageNumber: Int) -> [TableData] {
        guard blocks.count >= 4 else { return [] }

        // Group blocks by approximate Y position (row detection)
        var rows: [[OCRResult.TextBlock]] = []
        var currentRow: [OCRResult.TextBlock] = []
        var lastY: CGFloat = -1

        let sorted = blocks.sorted { $0.boundingBox.minY < $1.boundingBox.minY }

        for block in sorted {
            if lastY < 0 || abs(block.boundingBox.minY - lastY) < 0.05 {
                currentRow.append(block)
            } else {
                if !currentRow.isEmpty { rows.append(currentRow) }
                currentRow = [block]
            }
            lastY = block.boundingBox.minY
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        // Convert to TableData
        var tables: [TableData] = []
        for (rowIndex, row) in rows.enumerated() {
            let sortedRow = row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
            let cells = sortedRow.enumerated().map { (colIndex, block) in
                TableCell(
                    text: block.text,
                    boundingBox: block.boundingBox,
                    columnIndex: colIndex,
                    rowIndex: rowIndex
                )
            }

            if cells.count >= 2 {
                let minX = cells.map { $0.boundingBox.minX }.min() ?? 0
                let maxX = cells.map { $0.boundingBox.maxX }.max() ?? 0
                let minY = cells.map { $0.boundingBox.minY }.min() ?? 0
                let maxY = cells.map { $0.boundingBox.maxY }.max() ?? 0

                tables.append(TableData(
                    pageNumber: pageNumber,
                    rows: cells,
                    boundingBox: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                ))
            }
        }

        return tables
    }

    // MARK: - Claude Structured Extraction

    /// Extract structured fields from OCR text using Claude.
    func extractStructuredFields(from text: String, onProgress: ProgressHandler?) async throws -> ExtractedFields {
        await onProgress?(ProcessingState(phase: .extractingFields, progress: 0.7, currentPage: 0, totalPages: 0))

        let service = getClaudeService()
        return try await service.extractStructuredData(ocrText: text)
    }

    /// Generate a summary of the document text.
    func generateSummary(from text: String, onProgress: ProgressHandler?) async throws -> String {
        await onProgress?(ProcessingState(phase: .analyzing, progress: 0.85, currentPage: 0, totalPages: 0))

        let service = getClaudeService()
        return try await service.summarize(text: text)
    }

    // MARK: - Field Extraction Helpers

    /// Extract specific field by name from OCR text.
    func extractField(named fieldName: String, from text: String) async throws -> [String] {
        let service = getClaudeService()

        let prompt = """
        Trích xuất tất cả giá trị của trường "\(fieldName)" từ văn bản sau.
        Chỉ trả về danh sách các giá trị tìm được, mỗi dòng một giá trị.
        Nếu không tìm thấy, trả về "NOT_FOUND".

        Văn bản:
        \(text.prefix(3000))
        """

        let result = try await service.chat(messages: [
            ClaudeAPIService.Message(role: "user", content: prompt)
        ])

        if result.contains("NOT_FOUND") {
            return []
        }

        return result.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Processing Result

struct ProcessingResult {
    let fullText: String
    let textBlocks: [OCRResult.TextBlock]
    let tables: [TableData]
    let extractedFields: ExtractedFields?
    let summary: String?
    let pageCount: Int

    /// Save processing result to Core Data document.
    func save(to document: CDDocument) {
        document.fullText = fullText
        document.isProcessed = true

        if let fields = extractedFields {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(fields) {
                document.extractedDataJSON = String(data: data, encoding: .utf8)
            }
        }
    }
}

// MARK: - Table Data

struct TableData {
    let pageNumber: Int
    let rows: [TableCell]
    let boundingBox: CGRect

    var csvContent: String {
        rows.map { $0.text }.joined(separator: ",")
    }
}

struct TableCell {
    let text: String
    let boundingBox: CGRect
    let columnIndex: Int
    let rowIndex: Int
}
