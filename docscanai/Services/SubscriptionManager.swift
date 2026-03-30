import Foundation
import StoreKit
import Combine

// MARK: - Subscription Product IDs
// IMPORTANT: Replace with your actual product IDs from App Store Connect
enum SubscriptionProductID: String, CaseIterable {
    case weekly = "com.docscanai.premium.weekly"
    case monthly = "com.docscanai.premium.monthly"
    case yearly = "com.docscanai.premium.yearly"

    var displayName: String {
        switch self {
        case .weekly: return "Hàng tuần"
        case .monthly: return "Hàng tháng"
        case .yearly: return "Hàng năm"
        }
    }

    var price: String {
        switch self {
        case .weekly: return "29.000đ"
        case .monthly: return "79.000đ"
        case .yearly: return "499.000đ"
        }
    }

    var savings: String? {
        switch self {
        case .weekly: return nil
        case .monthly: return "Tiết kiệm 30%"
        case .yearly: return "Tiết kiệm 60%"
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: Equatable {
    case notSubscribed
    case active(expiresAt: Date)
    case expired(expiresAt: Date)
    case loading

    var isPremium: Bool {
        if case .active = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .notSubscribed: return "Miễn phí"
        case .active(let expiresAt):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Premium (đến \(formatter.string(from: expiresAt)))"
        case .expired: return "Đã hết hạn"
        case .loading: return "Đang kiểm tra..."
        }
    }
}

// MARK: - Subscription Manager
/// Handles StoreKit 2 subscription logic with grace period support.
@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    @Published private(set) var status: SubscriptionStatus = .loading
    @Published private(set) var products: [StoreKit.Product] = []
    @Published private(set) var isPurchasing = false
    @Published private(set) var errorMessage: String?

    /// Grace period: 3 days after expiration
    private let gracePeriodDays = 3

    private var updateListenerTask: Task<Void, Error>?
    private let subscriptionGroupID = "docscanai_premium"

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Load available subscription products from App Store.
    func loadProducts() async {
        status = .loading
        do {
            let productIDs = Set(SubscriptionProductID.allCases.map(\.rawValue))
            let storeProducts = try await StoreKit.Product.products(for: productIDs)
            products = storeProducts.sorted { p1, p2 in
                p1.price < p2.price
            }
            await updateStatus()
        } catch {
            print("Failed to load products: \(error)")
            status = .notSubscribed
        }
    }

    // MARK: - Purchase

    /// Purchase a subscription.
    func purchase(_ product: StoreKit.Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateStatus()
                await transaction.finish()
                HapticManager.shared.success()
                isPurchasing = false
                return true

            case .pending:
                errorMessage = "Đơn hàng đang chờ xử lý"
                isPurchasing = false
                return false

            case .userCancelled:
                isPurchasing = false
                return false

            @unknown default:
                isPurchasing = false
                return false
            }
        } catch {
            errorMessage = "Lỗi: \(error.localizedDescription)"
            isPurchasing = false
            return false
        }
    }

    // MARK: - Restore

    /// Restore previous purchases.
    func restorePurchases() async {
        isPurchasing = true
        do {
            try await AppStore.sync()
            await updateStatus()
            HapticManager.shared.success()
        } catch {
            errorMessage = "Không thể khôi phục: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    // MARK: - Check Premium Access

    /// Check if user has premium access (including grace period).
    func hasPremiumAccess() -> Bool {
        switch status {
        case .active: return true
        case .expired(let expiresAt):
            let gracePeriodEnd = Calendar.current.date(byAdding: .day, value: gracePeriodDays, to: expiresAt) ?? expiresAt
            return Date() < gracePeriodEnd
        default: return false
        }
    }

    /// Check if a specific feature requires premium.
    func requiresPremium(for feature: PremiumFeature) -> Bool {
        if feature == .aiProcessing || feature == .unlimitedScans {
            return !hasPremiumAccess()
        }
        return false
    }

    // MARK: - Subscription Info

    /// Get detailed subscription info for display.
    func subscriptionInfo() -> [(productID: SubscriptionProductID, isBestValue: Bool)] {
        let bestValue: SubscriptionProductID = .yearly
        return SubscriptionProductID.allCases.map { product in
            (product, product == bestValue)
        }
    }

    // MARK: - Private

    private func updateStatus() async {
        var latestActive: Transaction?
        var latestExpiration: Date?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                guard let productID = SubscriptionProductID(rawValue: transaction.productID) else { continue }

                if productID != .weekly && productID != .monthly && productID != .yearly { continue }

                if transaction.revocationDate == nil {
                    if latestExpiration == nil || transaction.expirationDate ?? Date.distantPast > latestExpiration! {
                        latestActive = transaction
                        latestExpiration = transaction.expirationDate
                    }
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        if let _ = latestActive, let expiration = latestExpiration {
            if Date() < expiration {
                status = .active(expiresAt: expiration)
            } else {
                status = .expired(expiresAt: expiration)
            }
        } else {
            status = .notSubscribed
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    guard let self = self else { continue }
                    let transaction = try await self.checkVerified(result)
                    await self.updateStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Xác thực giao dịch thất bại"
        case .purchaseFailed: return "Mua hàng thất bại"
        }
    }
}

// MARK: - Premium Feature

enum PremiumFeature: String, CaseIterable {
    case aiProcessing = "AI Document Processing"
    case unlimitedScans = "Unlimited Scans"
    case cloudSync = "Cloud Sync"
    case advancedAnnotation = "Advanced Annotation"
    case prioritySupport = "Priority Support"
    case exportPDF = "Export Options"

    var displayName: String {
        switch self {
        case .aiProcessing: return "Xử lý AI"
        case .unlimitedScans: return "Quét không giới hạn"
        case .cloudSync: return "Đồng bộ đám mây"
        case .advancedAnnotation: return "Annotation nâng cao"
        case .prioritySupport: return "Hỗ trợ ưu tiên"
        case .exportPDF: return "Xuất PDF/Word"
        }
    }

    var description: String {
        switch self {
        case .aiProcessing: return "Trích xuất dữ liệu tự động bằng AI"
        case .unlimitedScans: return "Quét bao nhiêu tài liệu cũng được"
        case .cloudSync: return "Đồng bộ tài liệu lên iCloud"
        case .advancedAnnotation: return "Thêm chữ ký, watermark, stamp"
        case .prioritySupport: return "Nhận hỗ trợ ưu tiên 24/7"
        case .exportPDF: return "Xuất sang PDF, Word, Excel"
        }
    }

    var iconName: String {
        switch self {
        case .aiProcessing: return "brain.head.profile"
        case .unlimitedScans: return "doc.viewfinder"
        case .cloudSync: return "icloud"
        case .advancedAnnotation: return "pencil.tip.crop.circle"
        case .prioritySupport: return "star.fill"
        case .exportPDF: return "square.and.arrow.up"
        }
    }
}
