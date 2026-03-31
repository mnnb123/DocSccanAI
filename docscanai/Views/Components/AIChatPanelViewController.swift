import UIKit
import CoreData

// MARK: - AIChatPanelDelegate

protocol AIChatPanelDelegate: AnyObject {
    func chatPanelDidRequestSummary(_ panel: AIChatPanelViewController)
    func chatPanelDidRequestTranslate(_ panel: AIChatPanelViewController)
    func chatPanel(_ panel: AIChatPanelViewController, didSendMessage message: String)
    func chatPanelDidClose(_ panel: AIChatPanelViewController)
}

// MARK: - AIChatPanelViewController

/// AI Chat panel for document interaction.
/// Extracted from DocumentDetailViewController for better separation of concerns.
final class AIChatPanelViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: AIChatPanelDelegate?

    private var messages: [ChatMessageItem] = []
    private var document: CDDocument?
    private var isProcessing = false

    // MARK: - UI Elements

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = DSColors.secondaryBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "AI Chat"
        label.font = DSFonts.headline
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let brainIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        iv.tintColor = DSColors.primary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        btn.tintColor = DSColors.textTertiary
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        tv.separatorStyle = .none
        tv.backgroundColor = DSColors.background
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let actionsView: UIView = {
        let view = UIView()
        view.backgroundColor = DSColors.secondaryBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var summaryButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Tóm tắt"
        config.image = UIImage(systemName: "list.bullet")
        config.imagePadding = 4
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(summaryTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var translateButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Dịch"
        config.image = UIImage(systemName: "globe")
        config.imagePadding = 4
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(translateTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let inputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = DSColors.background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Hỏi về tài liệu..."
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .send
        tf.delegate = self
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = DSColors.primary
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadChatHistory()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DSColors.background

        view.addSubview(headerView)
        headerView.addSubview(brainIcon)
        headerView.addSubview(headerLabel)
        headerView.addSubview(closeButton)

        view.addSubview(tableView)
        view.addSubview(actionsView)
        view.addSubview(inputContainer)

        let actionsStack = UIStackView(arrangedSubviews: [summaryButton, translateButton])
        actionsStack.axis = .horizontal
        actionsStack.spacing = DSSpacing.m
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsView.addSubview(actionsStack)

        inputContainer.addSubview(textField)
        inputContainer.addSubview(sendButton)
        inputContainer.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            brainIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: DSSpacing.l),
            brainIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            brainIcon.widthAnchor.constraint(equalToConstant: DSSpacing.iconSize),

            headerLabel.leadingAnchor.constraint(equalTo: brainIcon.trailingAnchor, constant: DSSpacing.s),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -DSSpacing.l),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: actionsView.topAnchor),

            actionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionsView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),
            actionsView.heightAnchor.constraint(equalToConstant: 50),

            actionsStack.centerXAnchor.constraint(equalTo: actionsView.centerXAnchor),
            actionsStack.centerYAnchor.constraint(equalTo: actionsView.centerYAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),

            textField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: DSSpacing.l),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -DSSpacing.s),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -DSSpacing.l),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),

            loadingIndicator.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -DSSpacing.s),
            loadingIndicator.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
        ])
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods

    func configure(with document: CDDocument) {
        self.document = document
    }

    func addUserMessage(_ content: String) {
        let message = ChatMessageItem(
            documentId: document?.id ?? UUID(),
            role: .user,
            content: content
        )
        messages.append(message)
        tableView.reloadData()
        scrollToBottom()
    }

    func addAssistantMessage(_ content: String) {
        let message = ChatMessageItem(
            documentId: document?.id ?? UUID(),
            role: .assistant,
            content: content
        )
        messages.append(message)
        tableView.reloadData()
        scrollToBottom()
    }

    func setLoading(_ loading: Bool) {
        isProcessing = loading
        if loading {
            loadingIndicator.startAnimating()
            sendButton.isHidden = true
            textField.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            sendButton.isHidden = false
            textField.isEnabled = true
        }
    }

    func clearMessages() {
        messages.removeAll()
        tableView.reloadData()
    }

    // MARK: - Private Methods

    private func loadChatHistory() {
        guard let documentID = document?.id else { return }

        let request: NSFetchRequest<CDChatMessage> = CDChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "documentId == %@", documentID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        if let results = try? AppDelegate.shared.managedObjectContext.fetch(request) {
            messages = results.compactMap { cdMsg -> ChatMessageItem? in
                guard let id = cdMsg.id,
                      let content = cdMsg.content,
                      let roleStr = cdMsg.role,
                      let timestamp = cdMsg.timestamp,
                      let docId = cdMsg.documentId else { return nil }

                let role: MessageRole = roleStr == "user" ? .user : .assistant
                return ChatMessageItem(id: id, documentId: docId, role: role, content: content, timestamp: timestamp)
            }
            tableView.reloadData()
        }
    }

    private func scrollToBottom() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        delegate?.chatPanelDidClose(self)
    }

    @objc private func summaryTapped() {
        delegate?.chatPanelDidRequestSummary(self)
    }

    @objc private func translateTapped() {
        delegate?.chatPanelDidRequestTranslate(self)
    }

    @objc private func sendTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        delegate?.chatPanel(self, didSendMessage: text)
        textField.text = ""
    }
}

// MARK: - UITableViewDelegate & DataSource

extension AIChatPanelViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.identifier, for: indexPath) as! ChatMessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

// MARK: - UITextFieldDelegate

extension AIChatPanelViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
