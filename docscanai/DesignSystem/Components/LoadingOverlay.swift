import UIKit

/// Full-screen loading overlay with activity indicator.
final class LoadingOverlay {

    // MARK: - Properties

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = DSSpacing.radiusLarge
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = DSSpacing.shadowRadius
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = DSColors.primary
        indicator.startAnimating()
        return indicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = DSFonts.bodyMedium
        label.textColor = DSColors.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    init(message: String? = nil) {
        setupViews()
        messageLabel.text = message
    }

    // MARK: - Setup

    private func setupViews() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        overlayView.addSubview(containerView)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: overlayView.superview!.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: overlayView.superview!.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: overlayView.superview!.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: overlayView.superview!.bottomAnchor),

            containerView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 280),

            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: DSSpacing.xl),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: DSSpacing.m),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: DSSpacing.xl),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -DSSpacing.xl),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -DSSpacing.xl),
        ])
    }

    // MARK: - Show / Hide

    func show(on view: UIView, animated: Bool = true) {
        view.addSubview(overlayView)

        overlayView.alpha = 0
        if animated {
            UIView.animate(withDuration: DSDuration.fast) {
                self.overlayView.alpha = 1
            }
        } else {
            overlayView.alpha = 1
        }
    }

    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: DSDuration.fast, animations: {
                self.overlayView.alpha = 0
            }) { _ in
                self.overlayView.removeFromSuperview()
                completion?()
            }
        } else {
            overlayView.removeFromSuperview()
            completion?()
        }
    }

    func updateMessage(_ message: String?) {
        messageLabel.text = message
    }
}
