import UIKit

// MARK: - Accessibility Helpers

/// Helper extensions for adding accessibility support throughout the app.
extension UIView {

    /// Add standard accessibility properties to a view.
    func configureAccessibility(
        label: String,
        hint: String? = nil,
        traits: UIAccessibilityTraits = .none
    ) {
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityHint = hint
        accessibilityTraits = traits
    }

    /// Add button accessibility.
    func configureAsButton(label: String, hint: String? = nil) {
        configureAccessibility(label: label, hint: hint, traits: .button)
    }

    /// Add header accessibility.
    func configureAsHeader(label: String) {
        configureAccessibility(label: label, traits: .header)
    }

    /// Add image accessibility.
    func configureAsImage(label: String) {
        configureAccessibility(label: label, traits: .image)
    }
}

// MARK: - UIButton Accessibility

extension UIButton {
    /// Configure accessibility with button traits.
    func configureAccessibility(label: String, hint: String? = nil) {
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityHint = hint
        accessibilityTraits = .button
    }
}

// MARK: - UITableViewCell Accessibility

extension UITableViewCell {
    /// Configure cell for accessibility.
    func configureAccessibility(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits = .none
    ) {
        isAccessibilityElement = true
        accessibilityLabel = label
        accessibilityValue = value
        accessibilityHint = hint
        accessibilityTraits = traits
    }
}

// MARK: - UIBarButtonItem Accessibility

extension UIBarButtonItem {
    /// Configure bar button for accessibility.
    func configureAccessibility(label: String, hint: String? = nil) {
        accessibilityLabel = label
        accessibilityHint = hint
        accessibilityTraits = .button
    }
}
