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

// MARK: - TypeSignatureViewController

/// Alternative: text-based signature.
final class TypeSignatureViewController: UIViewController {

    weak var delegate: SignatureViewControllerDelegate?
    var initialText: String = ""

    private var textField: UITextField!
    private var previewLabel: UILabel!
    private var cursiveFonts: [String] = [
        "Snell Roundhand",
        "Brush Script MT",
        "Copperplate",
        "Marker Felt",
        "Noteworthy-Light",
    ]
    private var selectedFontIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Chữ ký"
        view.backgroundColor = .systemBackground

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

        // Text field
        textField = UITextField()
        textField.placeholder = "Nhập tên của bạn"
        textField.font = UIFont(name: cursiveFonts[selectedFontIndex], size: 28)
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)

        // Preview
        previewLabel = UILabel()
        previewLabel.text = ""
        previewLabel.font = UIFont(name: cursiveFonts[selectedFontIndex], size: 36)
        previewLabel.textColor = .black
        previewLabel.textAlignment = .center
        previewLabel.backgroundColor = .white
        previewLabel.layer.cornerRadius = 8
        previewLabel.clipsToBounds = true
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewLabel)

        // Font picker
        let fontPickerLabels = cursiveFonts.map { (_: String) -> String in "ABC" }
        let fontPicker = UISegmentedControl(items: fontPickerLabels)
        fontPicker.selectedSegmentIndex = selectedFontIndex
        fontPicker.addTarget(self, action: #selector(fontChanged(_:)), for: .valueChanged)
        fontPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fontPicker)

        let hintLabel = UILabel()
        hintLabel.text = "Chọn phong cách chữ ký"
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textField.heightAnchor.constraint(equalToConstant: 50),

            hintLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            fontPicker.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 8),
            fontPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            fontPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            previewLabel.topAnchor.constraint(equalTo: fontPicker.bottomAnchor, constant: 32),
            previewLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            previewLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            previewLabel.heightAnchor.constraint(equalToConstant: 100),
        ])
    }

    @objc private func textChanged() {
        previewLabel.text = textField.text
    }

    @objc private func fontChanged(_ sender: UISegmentedControl) {
        selectedFontIndex = sender.selectedSegmentIndex
        let fontName = cursiveFonts[selectedFontIndex]
        textField.font = UIFont(name: fontName, size: 28)
        previewLabel.font = UIFont(name: fontName, size: 36)
        textChanged()
        HapticManager.shared.lightImpact()
    }

    @objc private func cancelTapped() {
        delegate?.signatureDidCancel()
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        guard let text = textField.text, !text.isEmpty else {
            HapticManager.shared.warning()
            return
        }

        // Convert text to PKDrawing
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100))
        let image = renderer.image { ctx in
            text.draw(
                in: CGRect(x: 10, y: 10, width: 380, height: 80),
                withAttributes: [
                    .font: UIFont(name: cursiveFonts[selectedFontIndex], size: 36) ?? UIFont.systemFont(ofSize: 36),
                    .foregroundColor: UIColor.black,
                ]
            )
        }

        let pngData = image.pngData()
        if let pngData = pngData, let drawing = try? PKDrawing(data: pngData) {
            HapticManager.shared.success()
            delegate?.signatureDidFinish(drawing: drawing)
        } else {
            delegate?.signatureDidCancel()
        }
        dismiss(animated: true)
    }
}
