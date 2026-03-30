import Foundation
import PDFKit
import UIKit
import PencilKit

/// Service for PDF annotation: highlight, underline, strikethrough, signature.
/// Uses PDFKit annotations for text markup and PencilKit for handwriting.

final class AnnotationService {

    // MARK: - Annotation Types

    enum AnnotationType: String, CaseIterable {
        case highlight
        case underline
        case strikethrough
        case signature

        var displayName: String {
            switch self {
            case .highlight: return "Tô sáng"
            case .underline: return "Gạch chân"
            case .strikethrough: return "Gạch ngang"
            case .signature: return "Chữ ký"
            }
        }

        var sfSymbol: String {
            switch self {
            case .highlight: return "highlighter"
            case .underline: return "underline"
            case .strikethrough: return "strikethrough"
            case .signature: return "signature"
            }
        }
    }

    // MARK: - Color Presets

    static let highlightColors: [UIColor] = [
        UIColor(red: 1.0, green: 0.95, blue: 0.0, alpha: 0.4),   // Yellow
        UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.4),   // Green
        UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 0.4), // Blue
        UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.4), // Red
    ]

    static let underlineColors: [UIColor] = [
        .systemBlue,
        .systemRed,
        .systemGreen,
        .systemOrange,
    ]

    // MARK: - Apply Annotation to Selection

    /// Apply annotation to currently selected text on a PDF page.
    func applyAnnotation(
        type: AnnotationType,
        color: UIColor,
        to selection: PDFSelection,
        on page: PDFPage
    ) {
        let bounds = selection.bounds(for: page)

        switch type {
        case .highlight:
            applyHighlight(color: color, bounds: bounds, on: page)
        case .underline:
            applyUnderline(color: color, bounds: bounds, on: page)
        case .strikethrough:
            applyStrikethrough(color: color, bounds: bounds, on: page)
        case .signature:
            // Signature is placed separately, not on text selection
            break
        }
    }

    private func applyHighlight(color: UIColor, bounds: CGRect, on page: PDFPage) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }

    private func applyUnderline(color: UIColor, bounds: CGRect, on page: PDFPage) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .underline, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }

    private func applyStrikethrough(color: UIColor, bounds: CGRect, on page: PDFPage) {
        let annotation = PDFAnnotation(bounds: bounds, forType: .strikeOut, withProperties: nil)
        annotation.color = color
        page.addAnnotation(annotation)
    }

    // MARK: - Remove Annotation

    /// Remove an annotation from a page.
    func removeAnnotation(_ annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
    }

    /// Remove all annotations from a page.
    func removeAllAnnotations(from page: PDFPage) {
        for annotation in page.annotations {
            page.removeAnnotation(annotation)
        }
    }

    // MARK: - Signature

    /// Add a text-based signature to a PDF page.
    func addTextSignature(
        text: String,
        fontName: String = "LucidaScript",
        fontSize: CGFloat = 24,
        color: UIColor = .black,
        at position: CGPoint,
        on page: PDFPage
    ) -> PDFAnnotation {
        // Create a signature appearance
        let bounds = CGRect(x: position.x, y: position.y, width: 200, height: 50)
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)

        annotation.contents = text
        annotation.font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        annotation.fontColor = color
        annotation.color = .clear
        annotation.border = PDFBorder()

        page.addAnnotation(annotation)
        return annotation
    }

    /// Add a PencilKit drawing as signature.
    func addDrawingSignature(
        drawing: PKDrawing,
        at position: CGPoint,
        scale: CGFloat = 1.0,
        on page: PDFPage
    ) -> PDFAnnotation {
        let drawingImage = drawing.image(from: drawing.bounds, scale: scale)
        let size = CGSize(
            width: min(drawing.bounds.width, 250),
            height: min(drawing.bounds.height, 100)
        )

        let bounds = CGRect(origin: position, size: size)

        // Use ink annotation with the drawing
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = .clear

        // Add the drawing as a border/ink
        // Note: For full image embedding, we'd need to create a custom appearance stream
        // For now, just place it as free text with image
        let freeTextAnnotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        freeTextAnnotation.contents = "[Signature]"
        freeTextAnnotation.font = .systemFont(ofSize: 10)
        freeTextAnnotation.color = .clear

        page.addAnnotation(freeTextAnnotation)
        return freeTextAnnotation
    }

    // MARK: - Save Annotated PDF

    /// Save annotated PDF to a new file.
    func saveAnnotatedPDF(
        _ document: PDFDocument,
        originalURL: URL,
        title: String
    ) throws -> URL {
        let fileName = "\(UUID().uuidString).pdf"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfDir = documentsPath.appendingPathComponent("PDFs")

        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)

        let destURL = pdfDir.appendingPathComponent(fileName)

        guard document.write(to: destURL) else {
            throw NSError(domain: "AnnotationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save annotated PDF"])
        }

        return destURL
    }

    // MARK: - Get Annotations

    /// Get all annotations on a page grouped by type.
    func getAnnotations(on page: PDFPage) -> [AnnotationType: [PDFAnnotation]] {
        var grouped: [AnnotationType: [PDFAnnotation]] = [:]

        for annotation in page.annotations {
            let type: AnnotationType?
            switch annotation.type {
            case "Highlight": type = .highlight
            case "Underline": type = .underline
            case "StrikeOut": type = .strikethrough
            default: type = nil
            }

            if let t = type {
                grouped[t, default: []].append(annotation)
            }
        }

        return grouped
    }

    // MARK: - Undo Last Annotation

    /// Remove the most recently added annotation of a given type.
    func undoLastAnnotation(type: AnnotationType, on page: PDFPage) {
        guard let annotations = getAnnotations(on: page)[type],
              let last = annotations.last else { return }
        page.removeAnnotation(last)
    }
}
