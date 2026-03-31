import UIKit

/// Design System: Typography tokens following Apple HIG.
enum DSFonts {
    // MARK: - Large Title
    static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
    static let title1 = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let title2 = UIFont.systemFont(ofSize: 22, weight: .bold)
    static let title3 = UIFont.systemFont(ofSize: 20, weight: .semibold)

    // MARK: - Headlines
    static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let headlineMedium = UIFont.systemFont(ofSize: 16, weight: .semibold)

    // MARK: - Body
    static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let bodyMedium = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let bodySmall = UIFont.systemFont(ofSize: 13, weight: .regular)

    // MARK: - Captions
    static let caption1 = UIFont.systemFont(ofSize: 12, weight: .regular)
    static let caption2 = UIFont.systemFont(ofSize: 11, weight: .regular)

    // MARK: - Special
    static let callout = UIFont.systemFont(ofSize: 16, weight: .regular)
    static let footnote = UIFont.systemFont(ofSize: 13, weight: .regular)

    // MARK: - Monospace (for code/technical text)
    static let monospace = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let monospaceSmall = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    // MARK: - Signature Fonts
    static let signatureFonts = [
        "Snell Roundhand",
        "Bradley Hand",
        "Marker Felt",
        "Noteworthy-Light",
        "Georgia"
    ]
}
