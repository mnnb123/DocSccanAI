import UIKit
import StoreKit

// MARK: - Subscription View Controller
/// Paywall screen for subscription upsell.
final class SubscriptionViewController: UIViewController {

    // MARK: - Properties

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Mở khóa Premium"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Trải nghiệm đầy đủ tính năng\nDocScan AI"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    private let featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let plansStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    private let subscribeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Đăng ký ngay"
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let restoreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Khôi phục gói đã mua"
        config.baseForegroundColor = .systemBlue
        let btn = UIButton(configuration: config)
        return btn
    }()

    private let termsLabel: UILabel = {
        let label = UILabel()
        label.text = "Đăng ký sẽ tự động gia hạn.\nBạn có thể hủy bất kỳ lúc nào."
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        label.textColor = .tertiaryLabel
        label.numberOfLines = 2
        return label
    }()

    private var selectedPlanIndex = 1 // Monthly selected by default
    private var planButtons: [UIButton] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFeatures()
        setupPlans()
        setupActions()
        loadProducts()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Close button
        let closeBtn = UIButton(type: .system)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeBtn.tintColor = .tertiaryLabel
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        closeBtn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeBtn)

        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Header
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)

        // Features
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featuresStackView)

        // Plans
        plansStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(plansStackView)

        // Buttons
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subscribeButton)

        restoreButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(restoreButton)

        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(termsLabel)

        // Loading
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        // Constraints
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 32),
            closeBtn.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            featuresStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            featuresStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            featuresStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            plansStackView.topAnchor.constraint(equalTo: featuresStackView.bottomAnchor, constant: 32),
            plansStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            plansStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            subscribeButton.topAnchor.constraint(equalTo: plansStackView.bottomAnchor, constant: 32),
            subscribeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subscribeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            subscribeButton.heightAnchor.constraint(equalToConstant: 56),

            restoreButton.topAnchor.constraint(equalTo: subscribeButton.bottomAnchor, constant: 12),
            restoreButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            termsLabel.topAnchor.constraint(equalTo: restoreButton.bottomAnchor, constant: 16),
            termsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            termsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            termsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupFeatures() {
        let features: [PremiumFeature] = [.aiProcessing, .unlimitedScans, .cloudSync, .advancedAnnotation, .exportPDF]

        for feature in features {
            let row = createFeatureRow(feature: feature)
            featuresStackView.addArrangedSubview(row)
        }
    }

    private func createFeatureRow(feature: PremiumFeature) -> UIView {
        let container = UIView()

        let iconView = UIImageView(image: UIImage(systemName: feature.iconName))
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = feature.displayName
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let descLabel = UILabel()
        descLabel.text = feature.description
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(descLabel)

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(checkmark)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -8),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),

            checkmark.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            checkmark.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 24),
            checkmark.heightAnchor.constraint(equalToConstant: 24),
        ])

        return container
    }

    private func setupPlans() {
        let plans: [(SubscriptionProductID, String, String?)] = [
            (.weekly, "29.000đ / tuần", nil),
            (.monthly, "79.000đ / tháng", "Tiết kiệm 30%"),
            (.yearly, "499.000đ / năm", "Tiết kiệm 60%"),
        ]

        for (index, plan) in plans.enumerated() {
            let button = createPlanButton(
                title: plan.0.displayName,
                price: plan.1,
                badge: plan.2,
                tag: index
            )
            planButtons.append(button)
            plansStackView.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 70)
            ])
        }

        updatePlanSelection()
    }

    private func createPlanButton(title: String, price: String, badge: String?, tag: Int) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.subtitle = price
        config.titleAlignment = .leading
        config.baseForegroundColor = .label

        let btn = UIButton(configuration: config)
        btn.tag = tag
        btn.layer.cornerRadius = 12
        btn.layer.borderWidth = 2

        // Add badge label if available
        if let badge = badge {
            let badgeLabel = UILabel()
            badgeLabel.text = badge
            badgeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
            badgeLabel.textColor = .systemYellow
            badgeLabel.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
            badgeLabel.layer.cornerRadius = 8
            badgeLabel.clipsToBounds = true
            badgeLabel.textAlignment = .center
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            btn.addSubview(badgeLabel)

            NSLayoutConstraint.activate([
                badgeLabel.topAnchor.constraint(equalTo: btn.topAnchor, constant: 6),
                badgeLabel.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -12),
                badgeLabel.heightAnchor.constraint(equalToConstant: 20),
            ])
        }

        btn.addTarget(self, action: #selector(planSelected(_:)), for: .touchUpInside)

        return btn
    }

    private func setupActions() {
        subscribeButton.addTarget(self, action: #selector(subscribeTapped), for: .touchUpInside)
        restoreButton.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
    }

    // MARK: - Load Products

    private func loadProducts() {
        loadingIndicator.startAnimating()
        Task {
            await SubscriptionManager.shared.loadProducts()
            loadingIndicator.stopAnimating()
            updatePlanSelection()
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func planSelected(_ sender: UIButton) {
        selectedPlanIndex = sender.tag
        updatePlanSelection()
        HapticManager.shared.selectionChanged()
    }

    @objc private func subscribeTapped() {
        guard !SubscriptionManager.shared.isPurchasing else { return }

        let products = SubscriptionManager.shared.products
        guard selectedPlanIndex < products.count else {
            showAlert(title: "Lỗi", message: "Không tìm thấy sản phẩm")
            return
        }

        let product = products[selectedPlanIndex]

        Task {
            subscribeButton.configuration?.showsActivityIndicator = true
            subscribeButton.configuration?.title = "Đang xử lý..."

            let success = await SubscriptionManager.shared.purchase(product)

            subscribeButton.configuration?.showsActivityIndicator = false
            subscribeButton.configuration?.title = "Đăng ký ngay"

            if success {
                showAlert(title: "Thành công!", message: "Cảm ơn bạn đã đăng ký Premium") { [weak self] in
                    self?.dismiss(animated: true)
                }
            } else if let error = SubscriptionManager.shared.errorMessage {
                showAlert(title: "Lỗi", message: error)
            }
        }
    }

    @objc private func restoreTapped() {
        Task {
            restoreButton.configuration?.showsActivityIndicator = true
            restoreButton.configuration?.title = "Đang khôi phục..."

            await SubscriptionManager.shared.restorePurchases()

            restoreButton.configuration?.showsActivityIndicator = false
            restoreButton.configuration?.title = "Khôi phục gói đã mua"

            if SubscriptionManager.shared.hasPremiumAccess() {
                showAlert(title: "Thành công!", message: "Đã khôi phục gói Premium của bạn") { [weak self] in
                    self?.dismiss(animated: true)
                }
            } else {
                showAlert(title: "Thông báo", message: "Không tìm thấy gói đã mua trước đó")
            }
        }
    }

    // MARK: - Helpers

    private func updatePlanSelection() {
        for (index, btn) in planButtons.enumerated() {
            let isSelected = index == selectedPlanIndex
            btn.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.separator.cgColor
            btn.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .secondarySystemBackground
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - Premium Gate Modifier

/// Use this to gate premium features behind subscription.
extension UIViewController {

    /// Show paywall if feature requires premium and user is not subscribed.
    /// Returns true if paywall was shown.
    @discardableResult
    func showPaywallIfNeeded(for feature: PremiumFeature, presenter: UIViewController? = nil) -> Bool {
        guard SubscriptionManager.shared.requiresPremium(for: feature) else {
            return false
        }

        let paywall = SubscriptionViewController()
        paywall.modalPresentationStyle = .pageSheet
        if let sheet = paywall.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        let vc = presenter ?? self
        vc.present(paywall, animated: true)
        return true
    }

    /// Convenience: check if user is premium and optionally show paywall.
    var isUserPremium: Bool {
        SubscriptionManager.shared.hasPremiumAccess()
    }
}
