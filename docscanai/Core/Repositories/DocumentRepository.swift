import Foundation
import CoreData
import UIKit

/// Repository for all Core Data document operations.
/// Single source of truth for document CRUD.
final class DocumentRepository {

    // MARK: - Singleton

    static let shared = DocumentRepository()

    private var context: NSManagedObjectContext {
        AppDelegate.shared.managedObjectContext
    }

    private init() {}

    // MARK: - Create

    /// Save a new scanned document to Core Data.
    @discardableResult
    func saveDocument(
        title: String,
        pdfFileName: String,
        pageCount: Int,
        thumbnailFileName: String? = nil,
        fullText: String? = nil,
        extractedDataJSON: String? = nil,
        isProcessed: Bool = false
    ) -> CDDocument {
        let document = CDDocument(context: context)
        document.id = UUID()
        document.title = title
        document.pdfFileName = pdfFileName
        document.pageCount = Int32(pageCount)
        document.thumbnailFileName = thumbnailFileName
        document.fullText = fullText
        document.extractedDataJSON = extractedDataJSON
        document.isFavorite = false
        document.isSecured = false
        document.isProcessed = isProcessed
        document.createdAt = Date()
        document.lastOpenedAt = Date()

        save()
        return document
    }

    /// Save annotated document (creates new entry)
    @discardableResult
    func saveAnnotatedDocument(
        title: String,
        pdfFileName: String,
        pageCount: Int,
        sourceDocument: CDDocument? = nil
    ) -> CDDocument {
        let document = CDDocument(context: context)
        document.id = UUID()
        document.title = "\(title) (Đã chỉnh sửa)"
        document.pdfFileName = pdfFileName
        document.pageCount = Int32(pageCount)
        document.isFavorite = false
        document.isSecured = false
        document.isProcessed = true
        document.createdAt = Date()
        document.lastOpenedAt = Date()

        save()
        return document
    }

    // MARK: - Read

    /// Fetch all documents sorted by last opened
    func fetchAllDocuments() -> [CDDocument] {
        let request: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastOpenedAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch documents: \(error)")
            return []
        }
    }

    /// Fetch document by ID
    func fetchDocument(id: UUID) -> CDDocument? {
        let request: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    // MARK: - Update

    /// Update last opened date
    func markOpened(_ document: CDDocument) {
        document.lastOpenedAt = Date()
        save()
    }

    /// Toggle favorite
    func toggleFavorite(_ document: CDDocument) {
        document.isFavorite.toggle()
        save()
    }

    /// Save processing result
    func saveProcessingResult(_ result: ProcessingResult, to document: CDDocument) {
        document.fullText = result.fullText
        document.isProcessed = true

        if let fields = result.extractedFields {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(fields) {
                document.extractedDataJSON = String(data: data, encoding: .utf8)
            }
        }
        save()
    }

    // MARK: - Delete

    /// Delete document and its file
    func deleteDocument(_ document: CDDocument) {
        // Delete PDF file
        let documentsPath = FileManager.documentsDirectoryURL
        let pdfURL = documentsPath.appendingPathComponent("PDFs").appendingPathComponent(document.pdfFileName ?? "")
        try? FileManager.default.removeItem(at: pdfURL)

        // Delete thumbnail
        if let thumbnailPath = document.thumbnailFileName {
            let thumbURL = documentsPath.appendingPathComponent(thumbnailPath)
            try? FileManager.default.removeItem(at: thumbURL)
        }

        // Delete Core Data entry
        context.delete(document)
        save()
    }

    // MARK: - Folder Operations

    /// Create a new folder
    @discardableResult
    func createFolder(name: String, colorHex: String = "#007AFF") -> CDFolder {
        let folder = CDFolder(context: context)
        folder.id = UUID()
        folder.name = name
        folder.colorHex = colorHex
        folder.createdAt = Date()
        save()
        return folder
    }

    /// Fetch all folders
    func fetchFolders() -> [CDFolder] {
        let request: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Delete a folder
    func deleteFolder(_ folder: CDFolder) {
        context.delete(folder)
        save()
    }

    // MARK: - Private

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - Document Path Helper

extension DocumentRepository {

    /// Get full URL for a document's PDF file
    func pdfURL(for document: CDDocument) -> URL {
        FileManager.documentsDirectoryURL
            .appendingPathComponent("PDFs")
            .appendingPathComponent(document.pdfFileName ?? "")
    }

    /// Get full URL for a document's thumbnail
    func thumbnailURL(for document: CDDocument) -> URL? {
        guard let path = document.thumbnailFileName else { return nil }
        return FileManager.documentsDirectoryURL.appendingPathComponent(path)
    }
}
