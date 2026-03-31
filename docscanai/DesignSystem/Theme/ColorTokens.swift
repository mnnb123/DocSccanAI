import UIKit

/// Design System: Semantic color tokens following Apple HIG.
/// Use these tokens instead of hardcoded colors throughout the app.
enum DSColors {
    // MARK: - Primary Colors
    static let primary = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0)  // Brighter blue for dark mode
            : UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0) // System blue
    }

    static let primaryVariant = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            : UIColor(red: 0.0, green: 0.35, blue: 0.9, alpha: 1.0)
    }

    // MARK: - Surface Colors
    static let background = UIColor.systemBackground
    static let secondaryBackground = UIColor.secondarySystemBackground
    static let tertiaryBackground = UIColor.tertiarySystemBackground
    static let groupedBackground = UIColor.systemGroupedBackground

    // MARK: - Card / Elevated Surface
    static let surfaceCard = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
            : UIColor.white
    }

    // MARK: - Text Colors
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let textTertiary = UIColor.tertiaryLabel
    static let textQuaternary = UIColor.quaternaryLabel

    // MARK: - Semantic Colors
    static let success = UIColor.systemGreen
    static let warning = UIColor.systemOrange
    static let error = UIColor.systemRed
    static let info = UIColor.systemBlue

    // MARK: - Premium / Subscription
    static let premiumGold = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)
    static let premiumGoldBackground = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.15)

    // MARK: - Document States
    static let documentProcessed = UIColor.systemGreen.withAlphaComponent(0.2)
    static let documentFavorite = UIColor.systemYellow.withAlphaComponent(0.2)
    static let documentSecured = UIColor.systemPurple.withAlphaComponent(0.2)

    // MARK: - Annotation Colors
    static let highlightYellow = UIColor(red: 1.0, green: 0.95, blue: 0.0, alpha: 0.4)
    static let highlightGreen = UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.4)
    static let highlightBlue = UIColor(red: 0.0, green: 0.6, blue: 1.0, alpha: 0.4)
    static let highlightRed = UIColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.4)
}
