import Foundation
import Vision
import UIKit
import NaturalLanguage

/// On-device OCR using Vision framework.
/// Supports Vietnamese, English, and Chinese text recognition.
actor OCRService {

    enum OCRError: Error, LocalizedError {
        case imageConversionFailed
        case recognitionFailed(Error)
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: return "Failed to convert image for OCR"
            case .recognitionFailed(let e): return "Text recognition failed: \(e.localizedDescription)"
            case .noTextFound: return "No text found in image"
            }
        }
    }

    /// Supported languages for OCR.
    static let supportedLanguages = ["vi", "en", "zh-Hans", "zh-Hant", "ja", "ko"]

    /// Recognize text from a UIImage using Vision on-device OCR.
    func recognizeText(from image: UIImage, pageNumber: Int = 1) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else {
                    continuation.resume(returning: OCRResult(fullText: "", textBlocks: []))
                    return
                }

                var blocks: [OCRResult.TextBlock] = []
                var fullText = ""

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    let block = OCRResult.TextBlock(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: topCandidate.confidence,
                        pageNumber: pageNumber
                    )
                    blocks.append(block)
                    fullText += topCandidate.string + "\n"
                }

                continuation.resume(returning: OCRResult(fullText: fullText.trimmingCharacters(in: .whitespacesAndNewlines), textBlocks: blocks))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = Self.supportedLanguages
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    /// Batch process multiple images for OCR.
    func recognizeBatch(images: [UIImage]) async throws -> [OCRResult] {
        try await withThrowingTaskGroup(of: OCRResult.self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    try await self.recognizeText(from: image, pageNumber: index + 1)
                }
            }

            var results: [OCRResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    /// Estimate the language of the given text.
    func detectLanguage(of text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}
