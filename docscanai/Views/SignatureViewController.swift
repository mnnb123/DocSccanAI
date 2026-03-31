import UIKit
import PencilKit

// MARK: - SignatureViewControllerDelegate

protocol SignatureViewControllerDelegate: AnyObject {
    func signatureDidFinish(drawing: PKDrawing)
    func signatureDidCancel()
}

// MARK: - SignatureViewController

/// PencilKit-based handwritten signature canvas.
final class SignatureViewController: UIViewController {

    weak var delegate: SignatureViewControllerDelegate?

    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker!
    private var placeholderLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCanvas()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Chữ ký"
        view.backgroundColor = .systemBackground

        // Navigation
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Dùng",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )

        // Canvas
        canvasView = PKCanvasView()
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)

        // White card effect
        canvasView.layer.cornerRadius = 12
        canvasView.layer.borderWidth = 1
        canvasView.layer.borderColor = UIColor.systemGray4.cgColor
        canvasView.clipsToBounds = true

        // Placeholder hint
        placeholderLabel = UILabel()
        placeholderLabel.text = "Vẽ chữ ký của bạn ở đây"
        placeholderLabel.font = .italicSystemFont(ofSize: 16)
        placeholderLabel.textColor = .tertiaryLabel
        placeholderLabel.textAlignment = .center
        placeholderLabel.isUserInteractionEnabled = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        canvasView.addSubview(placeholderLabel)

        // Hint below
        let hintLabel = UILabel()
        hintLabel.text = "Dùng Apple Pencil hoặc ngón tay để vẽ"
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        // Clear button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Xóa", for: .normal)
        clearButton.setImage(UIImage(systemName: "trash"), for: .normal)
        clearButton.tintColor = .systemRed
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearButton)

        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            canvasView.heightAnchor.constraint(equalToConstant: 200),

            placeholderLabel.centerXAnchor.constraint(equalTo: canvasView.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),

            hintLabel.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 8),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            clearButton.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        canvasView.delegate = self
    }

    private func setupCanvas() {
        toolPicker = PKToolPicker()
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)

        // Default to pen tool, black ink
        let pen = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.tool = pen

        // Show drawing sheet style
        if #available(iOS 17.0, *) {
            // Use default tool picker on iOS 17+
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.signatureDidCancel()
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        guard !canvasView.drawing.bounds.isEmpty else {
            HapticManager.shared.warning()
            return
        }

        HapticManager.shared.success()
        delegate?.signatureDidFinish(drawing: canvasView.drawing)
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        canvasView.drawing = PKDrawing()
        HapticManager.shared.lightImpact()
        placeholderLabel.isHidden = false
    }
}

// MARK: - PKCanvasViewDelegate

extension SignatureViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        placeholderLabel.isHidden = !canvasView.drawing.bounds.isEmpty
    }
}
