import XCTest
@testable import DocScanAI

// MARK: - DesignSystem Tests

final class ColorTokensTests: XCTestCase {

    func testDSColors_primary() {
        // Primary color should exist and be non-nil
        XCTAssertNotNil(DSColors.primary)
    }

    func testDSColors_surfaceCard() {
        XCTAssertNotNil(DSColors.surfaceCard)
    }

    func testDSColors_annotationColors() {
        XCTAssertNotNil(DSColors.highlightYellow)
        XCTAssertNotNil(DSColors.highlightGreen)
        XCTAssertNotNil(DSColors.highlightBlue)
        XCTAssertNotNil(DSColors.highlightRed)
    }

    func testDSColors_premiumColors() {
        XCTAssertNotNil(DSColors.premiumGold)
        XCTAssertNotNil(DSColors.premiumGoldBackground)
    }
}

final class TypographyTests: XCTestCase {

    func testDSFonts_largeTitle() {
        XCTAssertNotNil(DSFonts.largeTitle)
    }

    func testDSFonts_body() {
        XCTAssertNotNil(DSFonts.body)
    }

    func testDSFonts_signatureFonts() {
        XCTAssertFalse(DSFonts.signatureFonts.isEmpty)
        XCTAssertGreaterThan(DSFonts.signatureFonts.count, 3)
    }
}

final class SpacingTests: XCTestCase {

    func testDSSpacing_baseUnit() {
        XCTAssertEqual(DSSpacing.unit, 4)
    }

    func testDSSpacing_cardPadding() {
        XCTAssertGreaterThan(DSSpacing.cardPadding, 0)
    }

    func testDSSpacing_cornerRadius() {
        XCTAssertGreaterThan(DSSpacing.radiusMedium, 0)
        XCTAssertGreaterThan(DSSpacing.radiusLarge, DSSpacing.radiusMedium)
    }

    func testDSSpacing_thumbnailSize() {
        XCTAssertGreaterThan(DSSpacing.thumbnailWidth, 0)
        XCTAssertGreaterThan(DSSpacing.thumbnailHeight, 0)
    }
}

final class DurationTests: XCTestCase {

    func testDSDuration_instant() {
        XCTAssertGreaterThan(DSDuration.instant, 0)
    }

    func testDSDuration_order() {
        XCTAssertLessThan(DSDuration.instant, DSDuration.fast)
        XCTAssertLessThan(DSDuration.fast, DSDuration.normal)
        XCTAssertLessThan(DSDuration.normal, DSDuration.slow)
    }
}
