import Foundation
import CoreGraphics

/// Design System: Spacing and layout constants.
enum DSSpacing {
    // MARK: - Base Unit
    /// Base spacing unit = 4pt (Apple HIG standard)
    static let unit: CGFloat = 4

    // MARK: - Standard Spacing
    static let xxxs: CGFloat = 1
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    // MARK: - Section Spacing
    static let section: CGFloat = 24
    static let sectionLarge: CGFloat = 32
    static let page: CGFloat = 40

    // MARK: - Component Spacing
    static let cardPadding: CGFloat = 16
    static let cellPadding: CGFloat = 12
    static let buttonPadding: CGFloat = 12
    static let iconSize: CGFloat = 24
    static let iconSizeSmall: CGFloat = 20
    static let iconSizeLarge: CGFloat = 32

    // MARK: - Corner Radius
    static let radiusSmall: CGFloat = 6
    static let radiusMedium: CGFloat = 10
    static let radiusLarge: CGFloat = 14
    static let radiusXLarge: CGFloat = 20
    static let radiusFull: CGFloat = 9999  // Pill shape

    // MARK: - Shadow
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: Float = 0.08
    static let shadowOffset = CGSize(width: 0, height: 2)

    // MARK: - Grid
    static let gridSpacing: CGFloat = 12
    static let gridItemMinWidth: CGFloat = 150

    // MARK: - Document Thumbnail
    static let thumbnailWidth: CGFloat = 120
    static let thumbnailHeight: CGFloat = 160
    static let thumbnailCornerRadius: CGFloat = 8
}

/// Design System: Animation durations.
enum DSDuration {
    static let instant: TimeInterval = 0.1
    static let fast: TimeInterval = 0.2
    static let normal: TimeInterval = 0.3
    static let slow: TimeInterval = 0.5
}
