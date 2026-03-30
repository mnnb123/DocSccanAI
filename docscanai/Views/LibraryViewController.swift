import UIKit
import CoreData
import SwiftUI

/// Library view controller with document list.
final class LibraryViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var emptyStateView: UIView!
    private var segmentedControl: UISegmentedControl!
    private var isGridMode = true

    private var documents: [CDDocument] = []
    private var filteredDocuments: [CDDocument] = []
    private var searchController: UISearchController!

    private lazy var fetchedResultsController: NSFetchedResultsController<CDDocument> = {
        let request: NSFetchRequest<CDDocument> = CDDocument.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDDocument.lastOpenedAt, ascending: false)]

        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: AppDelegate.shared.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        fetchDocuments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchDocuments()
    }

    private func setupUI() {
        title = "Thư viện"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        // Segmented control
        segmentedControl = UISegmentedControl(items: ["Lưới", "Danh sách"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        // Collection View
        let layout = createGridLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DocumentGridCell.self, forCellWithReuseIdentifier: DocumentGridCell.identifier)
        collectionView.register(DocumentListCell.self, forCellWithReuseIdentifier: DocumentListCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Empty state
        emptyStateView = createEmptyStateView()
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    private func setupNavigationBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Tìm kiếm tài liệu"
        navigationItem.searchController = searchController

        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "folder.badge.plus"),
            style: .plain,
            target: self,
            action: #selector(createFolder)
        )

        let moreButton = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: self,
            action: #selector(showMoreOptions)
        )

        navigationItem.rightBarButtonItems = [moreButton, addButton]
    }

    private func createGridLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(220)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(220)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func createListLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func createEmptyStateView() -> UIView {
        let container = UIView()

        let icon = UIImageView(image: UIImage(systemName: "doc.text"))
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Chưa có tài liệu"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let sublabel = UILabel()
        sublabel.text = "Quét tài liệu đầu tiên từ tab \"Quét\""
        sublabel.font = .systemFont(ofSize: 14)
        sublabel.textColor = .tertiaryLabel
        sublabel.textAlignment = .center
        sublabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(icon)
        container.addSubview(label)
        container.addSubview(sublabel)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: container.topAnchor),
            icon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),

            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            sublabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            sublabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sublabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sublabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func fetchDocuments() {
        do {
            try fetchedResultsController.performFetch()
            documents = fetchedResultsController.fetchedObjects ?? []
            filteredDocuments = documents
            updateEmptyState()
            collectionView.reloadData()
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    private func updateEmptyState() {
        emptyStateView.isHidden = !filteredDocuments.isEmpty
        collectionView.isHidden = filteredDocuments.isEmpty
    }

    @objc private func viewModeChanged() {
        isGridMode = segmentedControl.selectedSegmentIndex == 0
        HapticManager.shared.lightImpact()

        let layout = isGridMode ? createGridLayout() : createListLayout()
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.reloadData()
    }

    @objc private func createFolder() {
        let alert = UIAlertController(title: "Thư mục mới", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Tên thư mục"
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tạo", style: .default) { _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else { return }
            let ctx = AppDelegate.shared.managedObjectContext
            let folder = CDFolder(context: ctx)
            folder.id = UUID()
            folder.name = name
            folder.createdAt = Date()
            folder.colorHex = "#007AFF"
            try? ctx.save()
            HapticManager.shared.success()
        })
        present(alert, animated: true)
    }

    @objc private func showMoreOptions() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Sắp xếp theo", style: .default) { _ in })
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(sheet, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension LibraryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredDocuments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let doc = filteredDocuments[indexPath.item]

        if isGridMode {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentGridCell.identifier, for: indexPath) as! DocumentGridCell
            cell.configure(with: doc)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentListCell.identifier, for: indexPath) as! DocumentListCell
            cell.configure(with: doc)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension LibraryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        HapticManager.shared.lightImpact()
        let doc = filteredDocuments[indexPath.item]
        let detailVC = DocumentDetailViewController(document: doc)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let doc = filteredDocuments[indexPath.item]

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let favorite = UIAction(
                title: doc.isFavorite ? "Bỏ yêu thích" : "Yêu thích",
                image: UIImage(systemName: doc.isFavorite ? "star.slash" : "star")
            ) { [weak self] _ in
                doc.isFavorite.toggle()
                try? self?.fetchedResultsController.managedObjectContext.save()
                HapticManager.shared.lightImpact()
            }

            let delete = UIAction(
                title: "Xóa",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.confirmDelete(document: doc)
            }

            return UIMenu(children: [favorite, delete])
        }
    }

    private func confirmDelete(document: CDDocument) {
        let alert = UIAlertController(
            title: "Xóa tài liệu?",
            message: "Tài liệu \"\(document.title ?? "")\" sẽ bị xóa vĩnh viễn.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            let ctx = self?.fetchedResultsController.managedObjectContext ?? AppDelegate.shared.managedObjectContext
            ctx.delete(document)
            try? ctx.save()
            HapticManager.shared.success()
        })
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension LibraryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""

        if query.isEmpty {
            filteredDocuments = documents
        } else {
            filteredDocuments = documents.filter {
                ($0.title ?? "").lowercased().contains(query) ||
                ($0.fullText ?? "").lowercased().contains(query)
            }
        }

        updateEmptyState()
        collectionView.reloadData()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension LibraryViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        documents = fetchedResultsController.fetchedObjects ?? []
        filteredDocuments = documents
        updateEmptyState()
        collectionView.reloadData()
    }
}

// MARK: - Grid Cell

final class DocumentGridCell: UICollectionViewCell {
    static let identifier = "DocumentGridCell"

    private let thumbnailView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let starImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        thumbnailView.backgroundColor = .tertiarySystemGroupedBackground
        thumbnailView.layer.cornerRadius = 8
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailView)

        iconImageView.image = UIImage(systemName: "doc.fill")
        iconImageView.tintColor = .tertiaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.addSubview(iconImageView)

        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .systemYellow
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starImageView.isHidden = true
        contentView.addSubview(starImageView)

        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        metaLabel.font = .systemFont(ofSize: 11)
        metaLabel.textColor = .secondaryLabel
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailView.widthAnchor, multiplier: 1.3),

            iconImageView.centerXAnchor.constraint(equalTo: thumbnailView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: thumbnailView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),

            starImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            starImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            metaLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            metaLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with doc: CDDocument) {
        titleLabel.text = doc.title ?? "Untitled"
        metaLabel.text = "\(doc.pageCount) trang • \((doc.lastOpenedAt ?? Date()).formatted(date: .abbreviated, time: .omitted))"
        starImageView.isHidden = !doc.isFavorite
    }
}

// MARK: - List Cell

final class DocumentListCell: UICollectionViewCell {
    static let identifier = "DocumentListCell"

    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let starImageView = UIImageView()
    private let chevronImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10

        iconView.backgroundColor = .tertiarySystemGroupedBackground
        iconView.layer.cornerRadius = 6
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        iconImageView.image = UIImage(systemName: "doc.fill")
        iconImageView.tintColor = .tertiaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconView.addSubview(iconImageView)

        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        metaLabel.font = .systemFont(ofSize: 12)
        metaLabel.textColor = .secondaryLabel
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metaLabel)

        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .systemYellow
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        starImageView.isHidden = true
        contentView.addSubview(starImageView)

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: starImageView.leadingAnchor, constant: -8),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            metaLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

            starImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    func configure(with doc: CDDocument) {
        titleLabel.text = doc.title ?? "Untitled"
        metaLabel.text = "\(doc.pageCount) trang • \((doc.lastOpenedAt ?? Date()).formatted(date: .abbreviated, time: .omitted))"
        starImageView.isHidden = !doc.isFavorite
    }
}
