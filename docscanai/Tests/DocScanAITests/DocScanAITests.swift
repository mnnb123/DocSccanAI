import XCTest
@testable import DocScanAI

// MARK: - SubscriptionManager Tests

final class SubscriptionManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - SubscriptionProductID Tests

    func testSubscriptionProductID_displayName() {
        XCTAssertEqual(SubscriptionProductID.weekly.displayName, "Hàng tuần")
        XCTAssertEqual(SubscriptionProductID.monthly.displayName, "Hàng tháng")
        XCTAssertEqual(SubscriptionProductID.yearly.displayName, "Hàng năm")
    }

    func testSubscriptionProductID_price() {
        XCTAssertEqual(SubscriptionProductID.weekly.price, "29.000đ")
        XCTAssertEqual(SubscriptionProductID.monthly.price, "79.000đ")
        XCTAssertEqual(SubscriptionProductID.yearly.price, "499.000đ")
    }

    func testSubscriptionProductID_savings() {
        XCTAssertNil(SubscriptionProductID.weekly.savings)
        XCTAssertEqual(SubscriptionProductID.monthly.savings, "Tiết kiệm 30%")
        XCTAssertEqual(SubscriptionProductID.yearly.savings, "Tiết kiệm 60%")
    }

    // MARK: - SubscriptionStatus Tests

    func testSubscriptionStatus_isPremium() {
        let notSubscribed = SubscriptionStatus.notSubscribed
        let futureDate = Date().addingTimeInterval(86400)
        let pastDate = Date().addingTimeInterval(-86400)

        XCTAssertFalse(notSubscribed.isPremium)
        XCTAssertTrue(SubscriptionStatus.active(expiresAt: futureDate).isPremium)
        XCTAssertFalse(SubscriptionStatus.expired(expiresAt: pastDate).isPremium)
        XCTAssertFalse(SubscriptionStatus.loading.isPremium)
    }

    func testSubscriptionStatus_statusText() {
        XCTAssertEqual(SubscriptionStatus.notSubscribed.statusText, "Miễn phí")

        let date = Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expectedDate = formatter.string(from: date)

        XCTAssertTrue(SubscriptionStatus.loading.statusText.contains("Đang kiểm tra"))
        XCTAssertTrue(SubscriptionStatus.active(expiresAt: date).statusText.contains("Premium"))
    }
}

// MARK: - PremiumFeature Tests

final class PremiumFeatureTests: XCTestCase {

    func testPremiumFeature_displayName() {
        XCTAssertEqual(PremiumFeature.aiProcessing.displayName, "Xử lý AI")
        XCTAssertEqual(PremiumFeature.unlimitedScans.displayName, "Quét không giới hạn")
        XCTAssertEqual(PremiumFeature.cloudSync.displayName, "Đồng bộ đám mây")
    }

    func testPremiumFeature_description() {
        XCTAssertFalse(PremiumFeature.aiProcessing.description.isEmpty)
        XCTAssertFalse(PremiumFeature.exportPDF.description.isEmpty)
    }

    func testPremiumFeature_iconName() {
        XCTAssertEqual(PremiumFeature.aiProcessing.iconName, "brain.head.profile")
        XCTAssertEqual(PremiumFeature.cloudSync.iconName, "icloud")
        XCTAssertEqual(PremiumFeature.exportPDF.iconName, "square.and.arrow.up")
    }

    func testPremiumFeature_allCases() {
        XCTAssertEqual(PremiumFeature.allCases.count, 6)
    }
}
