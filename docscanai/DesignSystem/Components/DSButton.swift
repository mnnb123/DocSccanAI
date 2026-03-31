import UIKit

/// Design System: Standard button with multiple styles.
final class DSButton: UIButton {

    enum Style {
        case primary
        case secondary
        case tertiary
        case destructive
        case premium
    }

    // MARK: - Properties

    private var buttonStyle: Style = .primary

    // MARK: - Init

    init(title: String, style: Style = .primary) {
        super.init(frame: .zero)
        self.buttonStyle = style
        setupButton(title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton(title: "")
    }

    // MARK: - Setup

    private func setupButton(title: String) {
        var config = makeConfiguration(for: buttonStyle)
        config.title = title
        configuration = config
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func makeConfiguration(for style: Style) -> UIButton.Configuration {
        switch style {
        case .primary:
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = DSColors.primary
            config.baseForegroundColor = .white
            config.cornerStyle = .medium

        case .secondary:
            var config = UIButton.Configuration.gray()
            config.baseBackgroundColor = DSColors.secondaryBackground
            config.baseForegroundColor = DSColors.primary
            config.cornerStyle = .medium

        case .tertiary:
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = DSColors.primary
            config.cornerStyle = .medium

        case .destructive:
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = DSColors.error
            config.baseForegroundColor = .white
            config.cornerStyle = .medium

        case .premium:
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = DSColors.premiumGold
            config.baseForegroundColor = .black
            config.cornerStyle = .medium
        }

        var config: UIButton.Configuration
        switch style {
        case .primary: var c = UIButton.Configuration.filled(); c.baseBackgroundColor = DSColors.primary; c.baseForegroundColor = .white; c.cornerStyle = .medium; config = c
        case .secondary: var c = UIButton.Configuration.gray(); c.baseBackgroundColor = DSColors.secondaryBackground; c.baseForegroundColor = DSColors.primary; c.cornerStyle = .medium; config = c
        case .tertiary: var c = UIButton.Configuration.plain(); c.baseForegroundColor = DSColors.primary; c.cornerStyle = .medium; config = c
        case .destructive: var c = UIButton.Configuration.filled(); c.baseBackgroundColor = DSColors.error; c.baseForegroundColor = .white; c.cornerStyle = .medium; config = c
        case .premium: var c = UIButton.Configuration.filled(); c.baseBackgroundColor = DSColors.premiumGold; c.baseForegroundColor = .black; c.cornerStyle = .medium; config = c
        }

        config.contentInsets = NSDirectionalEdgeInsets(
            top: DSSpacing.buttonPadding,
            leading: DSSpacing.l,
            bottom: DSSpacing.buttonPadding,
            trailing: DSSpacing.l
        )

        return config
    }

    // MARK: - Public Methods

    func setStyle(_ style: Style) {
        buttonStyle = style
        configuration = makeConfiguration(for: style)
    }

    func setLoading(_ loading: Bool) {
        if loading {
            configuration?.showsActivityIndicator = true
            configuration?.title = ""
            isEnabled = false
        } else {
            configuration?.showsActivityIndicator = false
            isEnabled = true
        }
    }

    func setIcon(_ systemName: String) {
        configuration?.image = UIImage(systemName: systemName)
        configuration?.imagePadding = DSSpacing.xs
    }
}
