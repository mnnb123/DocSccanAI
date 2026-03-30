import UIKit

// MARK: - ScanPreviewViewControllerDelegate

protocol ScanPreviewViewControllerDelegate: AnyObject {
    func scanPreviewDidSave(images: [UIImage], title: String)
    func scanPreviewDidCancel()
}

// MARK: - ScanPreviewViewController

/// Preview scanned images before saving — supports reorder, delete, rename.
final class ScanPreviewViewController: UIViewController {

    weak var delegate: ScanPreviewViewControllerDelegate?

    private var images: [UIImage]
    private var collectionView: UICollectionView!
    private var titleTextField: UITextField!
    private var pageCountLabel: UILabel!
    private var saveButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    // MARK: - Init

    init(images: [UIImage]) {
        self.images = images
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Xem trước"

        cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton

        saveButton = UIBarButtonItem(
            title: "Lưu",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        // Title input
        let titleContainer = UIView()
        titleContainer.backgroundColor = .secondarySystemGroupedBackground
        titleContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleContainer)

        titleTextField = UITextField()
        titleTextField.text = "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
        titleTextField.font = .systemFont(ofSize: 17, weight: .semibold)
        titleTextField.placeholder = "Tên tài liệu"
        titleTextField.borderStyle = .none
        titleTextField.returnKeyType = .done
        titleTextField.delegate = self
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleContainer.addSubview(titleTextField)

        // Page count
        pageCountLabel = UILabel()
        pageCountLabel.text = "\(images.count) trang"
        pageCountLabel.font = .systemFont(ofSize: 13)
        pageCountLabel.textColor = .secondaryLabel
        pageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageCountLabel)

        // Instructions
        let hintLabel = UILabel()
        hintLabel.text = "Kéo để sắp xếp lại thứ tự trang • Nhấn giữ để xóa"
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .tertiaryLabel
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        // Collection view — horizontal paged
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ScanPreviewCell.self, forCellWithReuseIdentifier: ScanPreviewCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleContainer.heightAnchor.constraint(equalToConstant: 56),

            titleTextField.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -16),
            titleTextField.centerYAnchor.constraint(equalTo: titleContainer.centerYAnchor),

            pageCountLabel.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 12),
            pageCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            hintLabel.topAnchor.constraint(equalTo: titleContainer.bottomAnchor, constant: 12),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            collectionView.topAnchor.constraint(equalTo: pageCountLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        HapticManager.shared.lightImpact()
        delegate?.scanPreviewDidCancel()
    }

    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            HapticManager.shared.error()
            return
        }

        HapticManager.shared.mediumImpact()
        delegate?.scanPreviewDidSave(images: images, title: title)
    }

    private func deletePage(at indexPath: IndexPath) {
        guard images.count > 1 else {
            HapticManager.shared.warning()
            return
        }

        images.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        pageCountLabel.text = "\(images.count) trang"
        HapticManager.shared.lightImpact()
    }
}

// MARK: - UICollectionViewDataSource

extension ScanPreviewViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScanPreviewCell.identifier, for: indexPath) as! ScanPreviewCell
        cell.configure(with: images[indexPath.item], pageNumber: indexPath.item + 1)
        cell.onDelete = { [weak self] in
            self?.deletePage(at: indexPath)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ScanPreviewViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height - 32
        let width = height * 0.75 // A4 aspect ratio
        return CGSize(width: width, height: height)
    }
}

// MARK: - UICollectionViewDragDelegate & DropDelegate

extension ScanPreviewViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = images[indexPath.item]
        let provider = NSItemProvider(object: item)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item
        return [dragItem]
    }
}

extension ScanPreviewViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else { return }

        collectionView.performBatchUpdates {
            images.remove(at: sourceIndexPath.item)
            images.insert(item.dragItem.localObject as! UIImage, at: destinationIndexPath.item)
            collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        }

        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        HapticManager.shared.lightImpact()
    }
}

// MARK: - UITextFieldDelegate

extension ScanPreviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - ScanPreviewCell

final class ScanPreviewCell: UICollectionViewCell {
    static let identifier = "ScanPreviewCell"

    private let imageView = UIImageView()
    private let pageLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let shadowView = UIView()

    var onDelete: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        // Shadow
        shadowView.backgroundColor = .white
        shadowView.layer.cornerRadius = 12
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.15
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowView.layer.shadowRadius = 12
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowView)

        // Image
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        // Page label
        pageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        pageLabel.textColor = .white
        pageLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        pageLabel.textAlignment = .center
        pageLabel.layer.cornerRadius = 12
        pageLabel.clipsToBounds = true
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pageLabel)

        // Delete button
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            shadowView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            pageLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            pageLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            pageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),
            pageLabel.heightAnchor.constraint(equalToConstant: 24),

            deleteButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            deleteButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    func configure(with image: UIImage, pageNumber: Int) {
        imageView.image = image
        pageLabel.text = "  \(pageNumber)  "
    }

    @objc private func deleteTapped() {
        onDelete?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        onDelete = nil
    }
}
