import UIKit
import PDFKit
import PencilKit

// MARK: - AnnotationToolbarDelegate

protocol AnnotationToolbarDelegate: AnyObject {
    func annotationToolbarDidSelectTool(_ tool: AnnotationService.AnnotationType)
    func annotationToolbarDidSelectColor(_ color: UIColor)
    func annotationToolbarDidRequestSignature()
    func annotationToolbarDidRequestUndo()
    func annotationToolbarDidRequestClear()
    func annotationToolbarDidFinish()
}

// MARK: - AnnotationToolbarViewController

/// Bottom sheet toolbar for PDF annotation tools.
final class AnnotationToolbarViewController: UIViewController {

    weak var delegate: AnnotationToolbarDelegate?

    private var toolButtons: [AnnotationService.AnnotationType: UIButton] = [:]
    private var colorButtons: [UIColor: UIButton] = [:]
    private var selectedTool: AnnotationService.AnnotationType = .highlight
    private var selectedColor: UIColor = AnnotationService.highlightColors[0]

    private lazy var toolStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var colorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var undoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        btn.tintColor = .label
        btn.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "trash"), for: .normal)
        btn.tintColor = .systemRed
        btn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var doneButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Xong"
        cfg.baseBackgroundColor = .systemBlue
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .capsule
        let btn = UIButton(configuration: cfg)
        btn.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectTool(.highlight)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Tool buttons
        for tool in AnnotationService.AnnotationType.allCases {
            let btn = createToolButton(tool: tool)
            toolButtons[tool] = btn
            toolStack.addArrangedSubview(btn)
        }

        // Separator
        let sep1 = UIView()
        sep1.backgroundColor = .separator
        sep1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sep1)

        // Color buttons
        for color in AnnotationService.highlightColors {
            let btn = createColorButton(color: color)
            colorButtons[color] = btn
            colorStack.addArrangedSubview(btn)
        }
        selectColor(AnnotationService.highlightColors[0])

        // Right side buttons
        let rightStack = UIStackView(arrangedSubviews: [undoButton, clearButton])
        rightStack.axis = .horizontal
        rightStack.spacing = 16
        rightStack.translatesAutoresizingMaskIntoConstraints = false

        // Done button
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(toolStack)
        view.addSubview(sep1)
        view.addSubview(colorStack)
        view.addSubview(rightStack)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            toolStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            toolStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            toolStack.heightAnchor.constraint(equalToConstant: 44),

            undoButton.centerYAnchor.constraint(equalTo: toolStack.centerYAnchor),
            clearButton.centerYAnchor.constraint(equalTo: toolStack.centerYAnchor),

            sep1.topAnchor.constraint(equalTo: toolStack.bottomAnchor, constant: 12),
            sep1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sep1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sep1.heightAnchor.constraint(equalToConstant: 1),

            colorStack.topAnchor.constraint(equalTo: sep1.bottomAnchor, constant: 12),
            colorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            colorStack.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -16),
            colorStack.heightAnchor.constraint(equalToConstant: 32),

            rightStack.centerYAnchor.constraint(equalTo: colorStack.centerYAnchor),
            rightStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            doneButton.topAnchor.constraint(equalTo: colorStack.bottomAnchor, constant: 16),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }

    private func createToolButton(tool: AnnotationService.AnnotationType) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: tool.sfSymbol), for: .normal)
        btn.tintColor = .secondaryLabel
        btn.backgroundColor = .secondarySystemGroupedBackground
        btn.layer.cornerRadius = 10
        btn.tag = AnnotationService.AnnotationType.allCases.firstIndex(of: tool) ?? 0
        btn.addTarget(self, action: #selector(toolTapped(_:)), for: .touchUpInside)

        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: 44),
            btn.heightAnchor.constraint(equalToConstant: 44),
        ])

        if tool == .signature {
            btn.addTarget(self, action: #selector(signatureTapped), for: .touchUpInside)
        }

        return btn
    }

    private func createColorButton(color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.clear.cgColor
        btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Selection

    private func selectTool(_ tool: AnnotationService.AnnotationType) {
        selectedTool = tool

        for (t, btn) in toolButtons {
            if t == tool {
                btn.backgroundColor = .systemBlue
                btn.tintColor = .white
            } else {
                btn.backgroundColor = .secondarySystemGroupedBackground
                btn.tintColor = .secondaryLabel
            }
        }

        HapticManager.shared.lightImpact()
        delegate?.annotationToolbarDidSelectTool(tool)
    }

    private func selectColor(_ color: UIColor) {
        selectedColor = color

        for (c, btn) in colorButtons {
            if c == color {
                btn.layer.borderColor = UIColor.systemBlue.cgColor
                btn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else {
                btn.layer.borderColor = UIColor.clear.cgColor
                btn.transform = .identity
            }
        }

        HapticManager.shared.lightImpact()
        delegate?.annotationToolbarDidSelectColor(color)
    }

    // MARK: - Actions

    @objc private func toolTapped(_ sender: UIButton) {
        let tool = AnnotationService.AnnotationType.allCases[sender.tag]
        selectTool(tool)
    }

    @objc private func colorTapped(_ sender: UIButton) {
        for (color, btn) in colorButtons {
            if btn == sender {
                selectColor(color)
                break
            }
        }
    }

    @objc private func signatureTapped() {
        HapticManager.shared.mediumImpact()
        delegate?.annotationToolbarDidRequestSignature()
    }

    @objc private func undoTapped() {
        HapticManager.shared.lightImpact()
        delegate?.annotationToolbarDidRequestUndo()
    }

    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "Xóa tất cả chú thích?",
            message: "Hành động này không thể hoàn tác.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            HapticManager.shared.mediumImpact()
            self?.delegate?.annotationToolbarDidRequestClear()
        })
        present(alert, animated: true)
    }

    @objc private func doneTapped() {
        HapticManager.shared.success()
        delegate?.annotationToolbarDidFinish()
    }
}