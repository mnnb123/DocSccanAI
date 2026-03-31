import UIKit

/// List cell for document library display.
final class DocumentListCell: UICollectionViewCell {

    static let identifier = "DocumentListCell"

    // MARK: - UI Elements

    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = DSColors.tertiaryBackground
        view.layer.cornerRadius = DSSpacing.radiusSmall
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "doc.fill"))
        iv.tintColor = DSColors.textTertiary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DSFonts.headline
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = DSFonts.caption1
        label.textColor = DSColors.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "star.fill"))
        iv.tintColor = DSColors.premiumGold
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    private let chevronImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = DSColors.textQuaternary
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = DSColors.secondaryBackground
        contentView.layer.cornerRadius = DSSpacing.radiusMedium

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(starImageView)
        contentView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.l),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 48),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: DSSpacing.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: DSSpacing.iconSize),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DSSpacing.m),
            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: DSSpacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -DSSpacing.s),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DSSpacing.xxs),
            metaLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: DSSpacing.m),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DSSpacing.m),

            starImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -DSSpacing.s),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.l),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    // MARK: - Configure

    func configure(with document: CDDocument) {
        titleLabel.text = document.title ?? "Untitled"
        metaLabel.text = "\(document.pageCount) trang • \((document.lastOpenedAt ?? Date()).formattedMonthDay)"
        starImageView.isHidden = !document.isFavorite
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        metaLabel.text = nil
        starImageView.isHidden = true
    }
}
