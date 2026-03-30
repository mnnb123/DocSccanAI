import UIKit
import PDFKit
import CoreData
import PencilKit

/// Document detail view — PDF viewer + AI chat panel.
final class DocumentDetailViewController: UIViewController {

    private let document: CDDocument

    private var pdfView: PDFView!
    private var chatContainerView: UIView!
    private var chatTableView: UITableView!
    private var chatInputContainer: UIView!
    private var chatTextField: UITextField!
    private var sendButton: UIButton!
    private var loadingIndicator: UIActivityIndicatorView!
    private var summaryButton: UIButton!
    private var translateButton: UIButton!
    private var toggleChatButton: UIButton!
    private var annotateButton: UIBarButtonItem!
    private var isAnnotationMode = false

    private var messages: [ChatMessageItem] = []
    private var isChatVisible = false
    private var selectedAnnotationTool: AnnotationService.AnnotationType = .highlight
    private var selectedAnnotationColor: UIColor = AnnotationService.highlightColors[0]
    private var isProcessing = false

    private let claudeService = ClaudeAPIService()

    init(document: CDDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
        loadChatHistory()

        // Update last opened
        document.lastOpenedAt = Date()
        try? AppDelegate.shared.managedObjectContext.save()
    }

    private func setupUI() {
        title = document.title ?? "Tài liệu"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false

        setupToolbar()
        setupPDFView()
        setupChatPanel()
    }

    private func setupToolbar() {
        toggleChatButton = UIButton(type: .system)
        toggleChatButton.setImage(UIImage(systemName: "bubble.left.and.bubble.right"), for: .normal)
        toggleChatButton.addTarget(self, action: #selector(toggleChat), for: .touchUpInside)

        let annotateBtn = UIButton(type: .system)
        annotateBtn.setImage(UIImage(systemName: "pencil.line"), for: .normal)
        annotateBtn.addTarget(self, action: #selector(toggleAnnotation), for: .touchUpInside)
        annotateButton = UIBarButtonItem(customView: annotateBtn)

        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareDocument)
        )

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )

        navigationItem.rightBarButtonItems = [moreButton, shareButton, UIBarButtonItem(customView: toggleChatButton), annotateButton]
    }

    private func setupPDFView() {
        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
    }

    private func setupChatPanel() {
        chatContainerView = UIView()
        chatContainerView.backgroundColor = .systemBackground
        chatContainerView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.isHidden = true
        view.addSubview(chatContainerView)

        // Header
        let headerView = UIView()
        headerView.backgroundColor = .secondarySystemGroupedBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.addSubview(headerView)

        let headerLabel = UILabel()
        headerLabel.text = "AI Chat"
        headerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)

        let brainIcon = UIImageView(image: UIImage(systemName: "brain.head.profile"))
        brainIcon.tintColor = .systemBlue
        brainIcon.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(brainIcon)

        // Table
        chatTableView = UITableView()
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        chatTableView.separatorStyle = .none
        chatTableView.backgroundColor = .systemBackground
        chatTableView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.addSubview(chatTableView)

        // Quick actions
        let actionsView = UIView()
        actionsView.backgroundColor = .secondarySystemGroupedBackground
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.addSubview(actionsView)

        summaryButton = createQuickActionButton(title: "Tóm tắt", icon: "list.bullet", action: #selector(requestSummary))
        translateButton = createQuickActionButton(title: "Dịch", icon: "globe", action: #selector(requestTranslate))

        let actionsStack = UIStackView(arrangedSubviews: [summaryButton!, translateButton!])
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.translatesAutoresizingMaskIntoConstraints = false
        actionsView.addSubview(actionsStack)

        // Input
        chatInputContainer = UIView()
        chatInputContainer.backgroundColor = .systemBackground
        chatInputContainer.translatesAutoresizingMaskIntoConstraints = false
        chatContainerView.addSubview(chatInputContainer)

        chatTextField = UITextField()
        chatTextField.placeholder = "Hỏi về tài liệu..."
        chatTextField.borderStyle = .roundedRect
        chatTextField.returnKeyType = .send
        chatTextField.delegate = self
        chatTextField.translatesAutoresizingMaskIntoConstraints = false
        chatInputContainer.addSubview(chatTextField)

        sendButton = UIButton(type: .system)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        chatInputContainer.addSubview(sendButton)

        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        chatInputContainer.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            chatContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            chatContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            chatContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),

            headerView.topAnchor.constraint(equalTo: chatContainerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            brainIcon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            brainIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            brainIcon.widthAnchor.constraint(equalToConstant: 20),

            headerLabel.leadingAnchor.constraint(equalTo: brainIcon.trailingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            chatTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            chatTableView.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            chatTableView.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            chatTableView.bottomAnchor.constraint(equalTo: actionsView.topAnchor),

            actionsView.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            actionsView.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            actionsView.bottomAnchor.constraint(equalTo: chatInputContainer.topAnchor),
            actionsView.heightAnchor.constraint(equalToConstant: 44),

            actionsStack.leadingAnchor.constraint(equalTo: actionsView.leadingAnchor, constant: 16),
            actionsStack.centerYAnchor.constraint(equalTo: actionsView.centerYAnchor),

            chatInputContainer.leadingAnchor.constraint(equalTo: chatContainerView.leadingAnchor),
            chatInputContainer.trailingAnchor.constraint(equalTo: chatContainerView.trailingAnchor),
            chatInputContainer.bottomAnchor.constraint(equalTo: chatContainerView.bottomAnchor),
            chatInputContainer.heightAnchor.constraint(equalToConstant: 56),

            chatTextField.leadingAnchor.constraint(equalTo: chatInputContainer.leadingAnchor, constant: 12),
            chatTextField.topAnchor.constraint(equalTo: chatInputContainer.topAnchor, constant: 8),
            chatTextField.bottomAnchor.constraint(equalTo: chatInputContainer.bottomAnchor, constant: -8),

            sendButton.leadingAnchor.constraint(equalTo: chatTextField.trailingAnchor, constant: 8),
            sendButton.trailingAnchor.constraint(equalTo: chatInputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: chatInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 30),

            loadingIndicator.leadingAnchor.constraint(equalTo: chatTextField.trailingAnchor, constant: 8),
            loadingIndicator.centerYAnchor.constraint(equalTo: chatInputContainer.centerYAnchor),
        ])
    }

    private func createQuickActionButton(title: String, icon: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 4
        config.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        config.baseForegroundColor = .systemBlue
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    private func loadPDF() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("PDFs").appendingPathComponent(document.pdfFileName ?? "")
        if let pdfDoc = PDFDocument(url: pdfURL) {
            pdfView.document = pdfDoc
        }
    }

    private func loadChatHistory() {
        let ctx = AppDelegate.shared.managedObjectContext
        let request: NSFetchRequest<CDChatMessage> = CDChatMessage.fetchRequest()
        request.predicate = NSPredicate(format: "documentId == %@", document.id! as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDChatMessage.timestamp, ascending: true)]

        if let results = try? ctx.fetch(request) {
            messages = results.map { cd in
                ChatMessageItem(
                    id: cd.id ?? UUID(),
                    documentId: cd.documentId ?? UUID(),
                    role: MessageRole(rawValue: cd.role ?? "user") ?? .user,
                    content: cd.content ?? "",
                    timestamp: cd.timestamp ?? Date()
                )
            }
            chatTableView.reloadData()
        }
    }

    @objc private func toggleChat() {
        isChatVisible.toggle()
        HapticManager.shared.lightImpact()

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.chatContainerView.isHidden = !self.isChatVisible
            self.toggleChatButton.setImage(
                UIImage(systemName: self.isChatVisible ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right"),
                for: .normal
            )
        }
    }

    @objc private func toggleAnnotation() {
        isAnnotationMode.toggle()
        HapticManager.shared.mediumImpact()

        if isAnnotationMode {
            showAnnotationToolbar()
            annotateButton.customView?.tintColor = .systemBlue
        } else {
            dismissAnnotationToolbar()
            annotateButton.customView?.tintColor = .label
        }
    }

    private func showAnnotationToolbar() {
        let toolbarVC = AnnotationToolbarViewController()
        toolbarVC.delegate = self

        let nav = UINavigationController(rootViewController: toolbarVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    private func dismissAnnotationToolbar() {
        // annotation mode sync
    }

    @objc private func shareDocument() {
        HapticManager.shared.lightImpact()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfURL = documentsPath.appendingPathComponent("PDFs").appendingPathComponent(document.pdfFileName ?? "")

        let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(activityVC, animated: true)
    }

    @objc private func showMoreOptions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        sheet.addAction(UIAlertAction(title: document.isFavorite ? "Bỏ yêu thích" : "Yêu thích", style: .default) { [weak self] _ in
            self?.document.isFavorite.toggle()
            try? AppDelegate.shared.managedObjectContext.save()
            HapticManager.shared.lightImpact()
        })

        sheet.addAction(UIAlertAction(title: "Xử lý AI", style: .default) { [weak self] _ in
            self?.processWithAI()
        })

        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(sheet, animated: true)
    }

    @objc private func sendMessage() {
        guard let text = chatTextField.text, !text.isEmpty else { return }

        let userMsg = ChatMessageItem(
            documentId: document.id ?? UUID(),
            role: .user,
            content: text
        )
        messages.append(userMsg)
        chatTextField.text = ""
        chatTableView.reloadData()
        scrollToBottom()
        HapticManager.shared.aiThinking()

        Task {
            await sendToClaude(userMsg: userMsg, userMessage: text)
        }
    }

    @objc private func requestSummary() {
        chatTextField.text = "Tóm tắt tài liệu này"
        sendMessage()
    }

    @objc private func requestTranslate() {
        chatTextField.text = "Dịch tài liệu sang tiếng Anh"
        sendMessage()
    }

    private func sendToClaude(userMsg: ChatMessageItem, userMessage: String) async {
        loadingIndicator.startAnimating()
        sendButton.isHidden = true

        do {
            var chatMessages: [ClaudeAPIService.Message] = []

            if let fullText = document.fullText, !fullText.isEmpty {
                chatMessages.append(ClaudeAPIService.Message(
                    role: "system",
                    content: "Bạn là trợ lý AI phân tích tài liệu. Trả lời dựa trên nội dung được cung cấp. Luôn trích dẫn số trang khi có thể."
                ))
                chatMessages.append(ClaudeAPIService.Message(
                    role: "user",
                    content: "Nội dung tài liệu:\n\(fullText.prefix(4000))"
                ))
            }

            chatMessages.append(ClaudeAPIService.Message(role: "user", content: userMessage))

            let response = try await claudeService.chat(messages: chatMessages)

            let assistantMsg = ChatMessageItem(
                documentId: document.id ?? UUID(),
                role: .assistant,
                content: response
            )

            await MainActor.run {
                messages.append(assistantMsg)
                chatTableView.reloadData()
                scrollToBottom()
                loadingIndicator.stopAnimating()
                sendButton.isHidden = false
                HapticManager.shared.success()

                // Save to Core Data
                let ctx = AppDelegate.shared.managedObjectContext
                let cdMsg = CDChatMessage(context: ctx)
                cdMsg.id = userMsg.id
                cdMsg.documentId = userMsg.documentId
                cdMsg.role = userMsg.role.rawValue
                cdMsg.content = userMsg.content
                cdMsg.timestamp = userMsg.timestamp

                let cdAssistantMsg = CDChatMessage(context: ctx)
                cdAssistantMsg.id = assistantMsg.id
                cdAssistantMsg.documentId = assistantMsg.documentId
                cdAssistantMsg.role = assistantMsg.role.rawValue
                cdAssistantMsg.content = assistantMsg.content
                cdAssistantMsg.timestamp = assistantMsg.timestamp

                try? ctx.save()
            }
        } catch {
            await MainActor.run {
                loadingIndicator.stopAnimating()
                sendButton.isHidden = false
                HapticManager.shared.error()

                let errorMsg = ChatMessageItem(
                    documentId: document.id ?? UUID(),
                    role: .assistant,
                    content: "Xin lỗi, đã xảy ra lỗi: \(error.localizedDescription)"
                )
                messages.append(errorMsg)
                chatTableView.reloadData()
            }
        }
    }

    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    @objc private func processWithAI() {
        let processorVC = AIProcessingViewController(document: document)
        let nav = UINavigationController(rootViewController: processorVC)
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource

extension DocumentDetailViewController: UITableViewDelegate, UITableViewDataSource {
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

extension DocumentDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
}

// MARK: - Chat Message Cell

final class ChatMessageCell: UITableViewCell {
    static let identifier = "ChatMessageCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        timeLabel.font = .systemFont(ofSize: 10)
        timeLabel.textColor = .tertiaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)
    }

    func configure(with msg: ChatMessageItem) {
        messageLabel.text = msg.content
        timeLabel.text = msg.timestamp.formatted(date: .omitted, time: .shortened)

        if msg.role == .user {
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8).isActive = true
        } else {
            bubbleView.backgroundColor = .secondarySystemGroupedBackground
            messageLabel.textColor = .label
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12).isActive = true
            bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8).isActive = true
        }

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            bubbleView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -2),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),

            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset constraints by removing all
        for constraint in contentView.constraints {
            constraint.isActive = false
        }
    }
}

// MARK: - AnnotationToolbarDelegate

extension DocumentDetailViewController: AnnotationToolbarDelegate {
    func annotationToolbarDidSelectTool(_ tool: AnnotationService.AnnotationType) {
        selectedAnnotationTool = tool
        // annotation mode enabled
    }

    func annotationToolbarDidSelectColor(_ color: UIColor) {
        selectedAnnotationColor = color
    }

    func annotationToolbarDidRequestSignature() {
        let sigVC = SignatureViewController()
        sigVC.delegate = self
        let nav = UINavigationController(rootViewController: sigVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    func annotationToolbarDidRequestUndo() {
        guard let page = pdfView.currentPage else { return }
        AnnotationService().undoLastAnnotation(type: selectedAnnotationTool, on: page)
        HapticManager.shared.lightImpact()
    }

    func annotationToolbarDidRequestClear() {
        guard let page = pdfView.currentPage else { return }
        AnnotationService().removeAllAnnotations(from: page)
        HapticManager.shared.success()
    }

    func annotationToolbarDidFinish() {
        dismiss(animated: true)
        isAnnotationMode = false
        annotateButton.customView?.tintColor = .label
        // annotation behavior reset
        saveAnnotatedDocument()
    }

    private func saveAnnotatedDocument() {
        guard let pdfDoc = pdfView.document else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfDir = documentsPath.appendingPathComponent("PDFs")
        try? FileManager.default.createDirectory(at: pdfDir, withIntermediateDirectories: true)

        let fileName = "\(UUID().uuidString).pdf"
        let destURL = pdfDir.appendingPathComponent(fileName)

        if pdfDoc.write(to: destURL) {
            let ctx = AppDelegate.shared.managedObjectContext
            let doc = CDDocument(context: ctx)
            doc.id = UUID()
            doc.title = (document.title ?? "Untitled") + " (annotated)"
            doc.pdfFileName = destURL.lastPathComponent
            doc.pageCount = Int32(pdfDoc.pageCount)
            doc.createdAt = Date()
            doc.lastOpenedAt = Date()
            doc.isFavorite = false
            doc.isSecured = false
            doc.isProcessed = document.isProcessed
            doc.fullText = document.fullText
            try? ctx.save()
            HapticManager.shared.success()
        }
    }
}

// MARK: - SignatureViewControllerDelegate

extension DocumentDetailViewController: SignatureViewControllerDelegate {
    func signatureDidFinish(drawing: PKDrawing) {
        guard let page = pdfView.currentPage else { return }
        let position = CGPoint(x: 50, y: page.bounds(for: .mediaBox).height - 100)
        _ = AnnotationService().addDrawingSignature(drawing: drawing, at: position, on: page)
        HapticManager.shared.success()
    }

    func signatureDidCancel() {
        // No action needed
    }
}
