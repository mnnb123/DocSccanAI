import UIKit

/// Chat message cell with proper constraint management.
/// Uses pre-created layout guides to avoid runtime constraint mutation.
final class ChatMessageCell: UITableViewCell {

    static let identifier = "ChatMessageCell"

    // MARK: - Layout Guides

    private let leadingBubble = UIView()
    private let trailingBubble = UIView()

    private var leadingConstraints: [NSLayoutConstraint] = []
    private var trailingConstraints: [NSLayoutConstraint] = []

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        leadingBubble.translatesAutoresizingMaskIntoConstraints = false
        trailingBubble.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(leadingBubble)
        contentView.addSubview(trailingBubble)

        // Store constraints separately - don't activate yet
        leadingConstraints = [
            leadingBubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            leadingBubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            leadingBubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            leadingBubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60),
        ]

        trailingConstraints = [
            trailingBubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            trailingBubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            trailingBubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60),
            trailingBubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
        ]
    }

    // MARK: - Configure

    func configure(with message: ChatMessageItem) {
        // Clear previous labels
        leadingBubble.subviews.forEach { $0.removeFromSuperview() }
        trailingBubble.subviews.forEach { $0.removeFromSuperview() }

        let isUser = message.role == .user

        // Select bubble container
        let bubble = isUser ? trailingBubble : leadingBubble
        let bubbleColor: UIColor = isUser ? DSColors.primary : DSColors.secondaryBackground

        // Create text label
        let textLabel = UILabel()
        textLabel.text = message.content
        textLabel.font = DSFonts.bodySmall
        textLabel.textColor = isUser ? .white : DSColors.textPrimary
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byWordWrapping
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        // Create time label
        let timeLabel = UILabel()
        timeLabel.text = message.timestamp.formatted(date: .omitted, time: .shortened)
        timeLabel.font = DSFonts.caption2
        timeLabel.textColor = isUser ? UIColor.white.withAlphaComponent(0.7) : DSColors.textTertiary
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stack view
        let stack = UIStackView(arrangedSubviews: [textLabel, timeLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = isUser ? .trailing : .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        bubble.backgroundColor = bubbleColor
        bubble.layer.cornerRadius = 16
        bubble.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
        ])

        // Show/hide bubbles
        leadingBubble.isHidden = isUser
        trailingBubble.isHidden = !isUser
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        leadingBubble.subviews.forEach { $0.removeFromSuperview() }
        trailingBubble.subviews.forEach { $0.removeFromSuperview() }
        leadingBubble.isHidden = false
        trailingBubble.isHidden = false
    }
}
