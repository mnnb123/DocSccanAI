import UIKit

/// Grid cell for document library display.
final class DocumentGridCell: UICollectionViewCell {

    static let identifier = "DocumentGridCell"

    // MARK: - UI Elements

    private let thumbnailView: UIView = {
        let view = UIView()
        view.backgroundColor = DSColors.tertiaryBackground
        view.layer.cornerRadius = DSSpacing.radiusMedium
        view.clipsToBounds = true
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
        label.font = DSFonts.bodyMedium
        label.numberOfLines = 2
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
        contentView.layer.cornerRadius = DSSpacing.radiusLarge
        contentView.clipsToBounds = true

        contentView.addSubview(thumbnailView)
        thumbnailView.addSubview(iconImageView)
        contentView.addSubview(starImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DSSpacing.cardPadding),
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.cardPadding),
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.cardPadding),
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailView.widthAnchor, multiplier: 1.3),

            iconImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: DSSpacing.iconSizeLarge),
            iconImageView.heightAnchor.constraint(equalToConstant: DSSpacing.iconSizeLarge),

            starImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DSSpacing.m),
            starImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.m),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: DSSpacing.s),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.cardPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.cardPadding),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: DSSpacing.xxs),
            metaLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.cardPadding),
            metaLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.cardPadding),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DSSpacing.cardPadding),
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
