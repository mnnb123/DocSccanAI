import Foundation
import VisionKit
import PDFKit
import UIKit

/// Service for scanning documents using VisionKit.
final class ScanService: NSObject {

    static let shared = ScanService()

    private override init() {
        super.init()
        createPDFDirectory()
        createThumbnailDirectory()
    }

    private var scanCompletionHandler: (([UIImage]) -> Void)?

    // MARK: - Directory Setup

    private var pdfDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("PDFs")
    }

    private var thumbnailDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("Thumbnails")
    }

    private func createPDFDirectory() {
        try? FileManager.default.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
    }

    private func createThumbnailDirectory() {
        try? FileManager.default.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)
    }

    // MARK: - VisionKit Scanner

    /// Check if document scanning is supported on this device.
    var isScannerSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    /// Create and configure the document scanner view controller.
    func makeScannerViewController(completion: @escaping ([UIImage]) -> Void) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        scanCompletionHandler = completion
        return scanner
    }

    // MARK: - PDF Generation

    /// Save scanned images as a PDF document.
    func savePDF(images: [UIImage], title: String) throws -> URL {
        let pdfDocument = PDFDocument()

        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
        }

        let fileName = "\(UUID().uuidString).pdf"
        let fileURL = pdfDirectory.appendingPathComponent(fileName)

        guard pdfDocument.write(to: fileURL) else {
            throw NSError(domain: "ScanService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to write PDF"])
        }

        return fileURL
    }

    /// Save a single image as PDF.
    func savePDF(image: UIImage, title: String) throws -> URL {
        try savePDF(images: [image], title: title)
    }

    // MARK: - Thumbnail Generation

    /// Generate and save thumbnail for a PDF.
    func generateThumbnail(for pdfURL: URL, size: CGSize = CGSize(width: 200, height: 280)) -> UIImage? {
        guard let pdfDocument = PDFDocument(url: pdfURL),
              let page = pdfDocument.page(at: 0) else { return nil }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(size.width / pageRect.width, size.height / pageRect.height)
        let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let thumbnail = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: scaledSize))

            ctx.cgContext.translateBy(x: 0, y: scaledSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)

            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = thumbnailDirectory.appendingPathComponent(fileName)

        if let jpegData = thumbnail.jpegData(compressionQuality: 0.7) {
            try? jpegData.write(to: fileURL)
        }

        return thumbnail
    }

    // MARK: - Import from Photos

    /// Import a PDF from Photos library.
    func importPDF(from image: UIImage) throws -> URL {
        try savePDF(image: image, title: "Imported")
    }

    // MARK: - Import from URL

    /// Import a PDF from a file URL (Files app).
    func importPDF(from sourceURL: URL) throws -> URL {
        let fileName = "\(UUID().uuidString).pdf"
        let destURL = pdfDirectory.appendingPathComponent(fileName)

        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } else {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        }

        return destURL
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension ScanService: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var images: [UIImage] = []
        for pageIndex in 0..<scan.pageCount {
            images.append(scan.imageOfPage(at: pageIndex))
        }
        scanCompletionHandler?(images)
        scanCompletionHandler = nil
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        scanCompletionHandler?([])
        scanCompletionHandler = nil
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("Scan failed: \(error.localizedDescription)")
        scanCompletionHandler?([])
        scanCompletionHandler = nil
    }
}
