import XCTest
@testable import DocScanAI

// MARK: - Date Extension Tests

final class DateExtensionTests: XCTestCase {

    func testFormattedVietnamese() {
        let date = Date(timeIntervalSince1970: 0)
        let result = date.formattedVietnamese
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("1970"))
    }

    func testFormattedShort() {
        let date = Date()
        let result = date.formattedShort
        XCTAssertFalse(result.isEmpty)
    }

    func testFormattedMonthDay() {
        let date = Date()
        let result = date.formattedMonthDay
        XCTAssertFalse(result.isEmpty)
    }

    func testRelativeTimeVietnamese() {
        let date = Date()
        let result = date.relativeTimeVietnamese
        XCTAssertFalse(result.isEmpty)
    }

    func testFormattedDateTime() {
        let date = Date()
        let result = date.formattedDateTime
        XCTAssertFalse(result.isEmpty)
    }
}

// MARK: - FileManager Extension Tests

final class FileManagerExtensionTests: XCTestCase {

    func testDocumentsDirectoryURL() {
        let url = FileManager.documentsDirectoryURL
        XCTAssertTrue(url.path.contains("Documents"))
    }

    func testPDFDirectoryURL() {
        let url = FileManager.pdfDirectoryURL
        XCTAssertTrue(url.path.contains("PDFs"))
    }

    func testThumbnailsDirectoryURL() {
        let url = FileManager.thumbnailsDirectoryURL
        XCTAssertTrue(url.path.contains("Thumbnails"))
    }

    func testFileSizeString() {
        let size = FileManager.fileSizeString(at: URL(fileURLWithPath: "/nonexistent"))
        XCTAssertEqual(size, "—")
    }

    func testFileSize() {
        let size = FileManager.fileSize(at: URL(fileURLWithPath: "/nonexistent"))
        XCTAssertEqual(size, 0)
    }
}

// MARK: - ImageUtils Tests

final class ImageUtilsTests: XCTestCase {

    func testThumbnailGeneration() {
        let image = UIImage(systemName: "doc.fill")!
        let thumbnail = ImageUtils.thumbnail(from: image, size: CGSize(width: 50, height: 50))
        XCTAssertNotNil(thumbnail)
    }

    func testThumbnailSize() {
        let image = UIImage(systemName: "doc.fill")!
        let targetSize = CGSize(width: 50, height: 70)
        let thumbnail = ImageUtils.thumbnail(from: image, size: targetSize)
        XCTAssertNotNil(thumbnail)
    }

    func testResize() {
        let image = UIImage(systemName: "doc.fill")!
        let resized = ImageUtils.resize(image, to: CGSize(width: 100, height: 100))
        XCTAssertNotNil(resized)
    }

    func testCornerRadius() {
        let image = UIImage(systemName: "doc.fill")!
        let rounded = ImageUtils.cornerRadius(image, radius: 8)
        XCTAssertNotNil(rounded)
    }
}
