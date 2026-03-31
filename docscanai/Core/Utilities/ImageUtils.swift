import UIKit
import ImageIO

/// Utility for image processing operations.
enum ImageUtils {

    /// Generate thumbnail from UIImage
    static func thumbnail(from image: UIImage, size: CGSize = CGSize(width: 120, height: 160)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Generate thumbnail from file URL (memory efficient, uses ImageIO)
    static func thumbnail(from url: URL, size: CGSize = CGSize(width: 240, height: 320)) -> UIImage? {
        let maxDimension = max(size.width, size.height) * UIScreen.main.scale
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Save thumbnail to disk cache
    static func saveThumbnail(_ image: UIImage, for documentID: UUID) -> URL? {
        let url = FileManager.thumbnailsDirectoryURL.appendingPathComponent("\(documentID.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    /// Load cached thumbnail
    static func loadThumbnail(for documentID: UUID) -> UIImage? {
        let url = FileManager.thumbnailsDirectoryURL.appendingPathComponent("\(documentID.uuidString).jpg")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Resize image to target size
    static func resize(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Apply corner radius
    static func cornerRadius(_ image: UIImage, radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: image.size)
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
            path.addClip()
            image.draw(in: rect)
        }
    }
}
