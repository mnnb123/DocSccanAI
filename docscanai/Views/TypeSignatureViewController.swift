import UIKit
import PencilKit

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
