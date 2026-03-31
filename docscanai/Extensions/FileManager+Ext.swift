import Foundation
import UIKit

extension FileManager {

    /// Documents directory URL
    static var documentsDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// PDFs subdirectory URL
    static var pdfDirectoryURL: URL {
        let url = documentsDirectoryURL.appendingPathComponent("PDFs")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Thumbnails directory URL
    static var thumbnailsDirectoryURL: URL {
        let url = documentsDirectoryURL.appendingPathComponent("Thumbnails")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Full file size string: "2.3 MB"
    static func fileSizeString(at url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return "—"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// Full file size in bytes
    static func fileSize(at url: URL) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

    /// Delete file safely
    static func deleteFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
