import UIKit

// MARK: - AI Processing View Controller

/// Full-screen processing UI with progress + cancel + results.
final class AIProcessingViewController: UIViewController {

    // MARK: - State

    private let document: CDDocument
    private let processor = DocumentAIProcessor()

    private var progressView: UIProgressView!
    private var phaseLabel: UILabel!
    private var pageLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    private var cancelButton: UIButton!
    private var resultContainer: UIView!
    private var summaryTextView: UITextView!
    private var fieldsStackView: UIStackView!
    private var doneButton: UIButton!

    private var processingTask: Task<Void, Never>?
    private var isCancelled = false

    // MARK: - Init

    init(document: CDDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startProcessing()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Đang xử lý AI"

        // Navigation
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Hủy", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)

        // Activity indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        // Phase label
        phaseLabel = UILabel()
        phaseLabel.text = "Đang trích xuất văn bản..."
        phaseLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        phaseLabel.textAlignment = .center
        phaseLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(phaseLabel)

        // Progress bar
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        // Page label
        pageLabel = UILabel()
        pageLabel.text = "Trang 0 / 0"
        pageLabel.font = .systemFont(ofSize: 13)
        pageLabel.textColor = .secondaryLabel
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageLabel)

        // Result container (hidden initially)
        resultContainer = UIView()
        resultContainer.isHidden = true
        resultContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultContainer)

        // Summary text view
        summaryTextView = UITextView()
        summaryTextView.font = .systemFont(ofSize: 15)
        summaryTextView.isEditable = false
        summaryTextView.backgroundColor = .secondarySystemGroupedBackground
        summaryTextView.layer.cornerRadius = 12
        summaryTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        summaryTextView.translatesAutoresizingMaskIntoConstraints = false
        resultContainer.addSubview(summaryTextView)

        // Fields stack
        fieldsStackView = UIStackView()
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = 8
        fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        resultContainer.addSubview(fieldsStackView)

        // Done button
        doneButton = UIButton(type: .system)
        var doneConfig = UIButton.Configuration.filled()
        doneConfig.title = "Xong"
        doneConfig.baseBackgroundColor = .systemBlue
        doneConfig.baseForegroundColor = .white
        doneConfig.cornerStyle = .large
        doneButton.configuration = doneConfig
        doneButton.isHidden = true
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        resultContainer.addSubview(doneButton)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),

            phaseLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 24),
            phaseLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            phaseLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            progressView.topAnchor.constraint(equalTo: phaseLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 4),

            pageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            pageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            resultContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            resultContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            summaryTextView.topAnchor.constraint(equalTo: resultContainer.topAnchor),
            summaryTextView.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor, constant: 16),
            summaryTextView.trailingAnchor.constraint(equalTo: resultContainer.trailingAnchor, constant: -16),
            summaryTextView.heightAnchor.constraint(equalToConstant: 200),

            fieldsStackView.topAnchor.constraint(equalTo: summaryTextView.bottomAnchor, constant: 16),
            fieldsStackView.leadingAnchor.constraint(equalTo: resultContainer.leadingAnchor, constant: 16),
            fieldsStackView.trailingAnchor.constraint(equalTo: resultContainer.trailingAnchor, constant: -16),

            doneButton.topAnchor.constraint(equalTo: fieldsStackView.bottomAnchor, constant: 24),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Processing

    private func startProcessing() {
        processingTask = Task { [weak self] in
            guard let self = self else { return }

            // Get PDF URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pdfURL = documentsPath.appendingPathComponent("PDFs").appendingPathComponent(self.document.pdfFileName ?? "")

            do {
                let result = try await self.processor.processPDF(at: pdfURL) { [weak self] state in
                    Task { @MainActor in
                        self?.updateUI(with: state)
                    }
                }

                if !self.isCancelled {
                    await MainActor.run {
                        self.showResults(result)
                    }
                }
            } catch {
                if !self.isCancelled {
                    await MainActor.run {
                        self.showError(error)
                    }
                }
            }
        }
    }

    @MainActor
    private func updateUI(with state: DocumentAIProcessor.ProcessingState) {
        phaseLabel.text = state.phase.rawValue
        progressView.setProgress(Float(state.progress), animated: true)

        if state.totalPages > 0 {
            pageLabel.text = "Trang \(state.currentPage) / \(state.totalPages)"
        } else {
            pageLabel.text = ""
        }
    }

    @MainActor
    private func showResults(_ result: ProcessingResult) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        phaseLabel.text = "Hoàn thành!"
        progressView.setProgress(1.0, animated: true)
        pageLabel.text = ""

        HapticManager.shared.success()

        // Save to document
        document.fullText = result.fullText
        document.isProcessed = true

        if let fields = result.extractedFields {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(fields) {
                document.extractedDataJSON = String(data: data, encoding: .utf8)
            }
        }
        try? AppDelegate.shared.managedObjectContext.save()

        // Show result UI
        resultContainer.isHidden = false

        if let summary = result.summary {
            summaryTextView.text = summary
        } else {
            summaryTextView.text = result.fullText.prefix(500) + "..."
        }

        // Show extracted fields
        if let fields = result.extractedFields {
            addFieldView(title: "Số hóa đơn", value: fields.invoiceNumber ?? "")
            addFieldView(title: "Ngày tháng", value: fields.dates.joined(separator: ", "))
            addFieldView(title: "Số tiền", value: fields.amounts.joined(separator: ", "))
            addFieldView(title: "Tên", value: fields.names.joined(separator: ", "))
        }

        cancelButton.isHidden = true
        doneButton.isHidden = false
    }

    private func addFieldView(title: String, value: String) {
        guard !value.isEmpty else { return }

        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .regular)
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
        ])

        fieldsStackView.addArrangedSubview(container)
    }

    @MainActor
    private func showError(_ error: Error) {
        activityIndicator.stopAnimating()
        HapticManager.shared.error()

        let alert = UIAlertController(
            title: "Lỗi xử lý",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Thử lại", style: .default) { [weak self] _ in
            self?.restart()
        })
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func restart() {
        // Reset UI
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        resultContainer.isHidden = true
        cancelButton.isHidden = false
        doneButton.isHidden = true
        progressView.setProgress(0, animated: false)

        // Clear fields
        for view in fieldsStackView.arrangedSubviews {
            view.removeFromSuperview()
        }

        isCancelled = false
        startProcessing()
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        isCancelled = true
        processingTask?.cancel()
        HapticManager.shared.lightImpact()
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        HapticManager.shared.success()
        dismiss(animated: true)
    }
}