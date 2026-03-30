import UIKit
import VisionKit
import CoreData
import PhotosUI
import UniformTypeIdentifiers

// MARK: - ScanViewController

/// Main scan screen: camera scan + Photos import + Files import.
final class ScanViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "doc.viewfinder"))
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quét tài liệu"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Chụp ảnh bằng camera, nhập từ Photos\nhoặc mở file PDF từ Files"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var scanButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Quét ngay"
        cfg.image = UIImage(systemName: "viewfinder")
        cfg.imagePadding = 8
        cfg.baseBackgroundColor = .systemBlue
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(openScanner), for: .touchUpInside)
        return btn
    }()

    private lazy var photosButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Nhập từ Photos"
        cfg.image = UIImage(systemName: "photo.on.rectangle")
        cfg.imagePadding = 8
        cfg.baseBackgroundColor = .secondarySystemGroupedBackground
        cfg.baseForegroundColor = .label
        cfg.cornerStyle = .large
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(openPhotoPicker), for: .touchUpInside)
        return btn
    }()

    private lazy var filesButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Mở từ Files"
        cfg.image = UIImage(systemName: "folder")
        cfg.imagePadding = 8
        cfg.baseBackgroundColor = .secondarySystemGroupedBackground
        cfg.baseForegroundColor = .label
        cfg.cornerStyle = .large
        let btn = UIButton(configuration: cfg)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(openFilesPicker), for: .touchUpInside)
        return btn
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var buttonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [scanButton, photosButton, filesButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "DocScan AI"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(buttonsStack)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            buttonsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            scanButton.heightAnchor.constraint(equalToConstant: 50),
            photosButton.heightAnchor.constraint(equalToConstant: 50),
            filesButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func openScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            showAlert(title: "Không hỗ trợ", message: "Thiết bị không hỗ trợ quét tài liệu.")
            return
        }

        HapticManager.shared.mediumImpact()
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }

    @objc private func openPhotoPicker() {
        HapticManager.shared.lightImpact()
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // Multiple selection

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func openFilesPicker() {
        HapticManager.shared.lightImpact()

        let supportedTypes: [UTType] = [.pdf, .image, .png, .jpeg]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    // MARK: - Processing

    private func processScannedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        showScanPreview(images: images)
    }

    /// Present scan preview screen for review/reorder before saving.
    private func showScanPreview(images: [UIImage]) {
        let previewVC = ScanPreviewViewController(images: images)
        previewVC.delegate = self
        let nav = UINavigationController(rootViewController: previewVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func saveScannedDocument(images: [UIImage], title: String) {
        activityIndicator.startAnimating()
        setUIEnabled(false)

        Task {
            do {
                let pdfURL = try ScanService.shared.savePDF(images: images, title: title)
                _ = ScanService.shared.generateThumbnail(for: pdfURL)

                let ctx = AppDelegate.shared.managedObjectContext
                let doc = CDDocument(context: ctx)
                doc.id = UUID()
                doc.title = title
                doc.pdfFileName = pdfURL.lastPathComponent
                doc.pageCount = Int32(images.count)
                doc.createdAt = Date()
                doc.lastOpenedAt = Date()
                doc.isFavorite = false
                doc.isSecured = false
                doc.isProcessed = false

                try ctx.save()

                await MainActor.run {
                    activityIndicator.stopAnimating()
                    setUIEnabled(true)
                    HapticManager.shared.success()

                    let ok = UIAlertController(
                        title: "Đã lưu!",
                        message: "\"\(title)\" đã được lưu vào Thư viện.",
                        preferredStyle: .alert
                    )
                    ok.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ok, animated: true)
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    setUIEnabled(true)
                    HapticManager.shared.error()
                    showAlert(title: "Lỗi", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setUIEnabled(_ enabled: Bool) {
        scanButton.isEnabled = enabled
        photosButton.isEnabled = enabled
        filesButton.isEnabled = enabled

        if enabled {
            activityIndicator.stopAnimating()
            view.isUserInteractionEnabled = true
        } else {
            activityIndicator.startAnimating()
            view.isUserInteractionEnabled = true
        }
    }
}

// MARK: - VNDocumentCameraViewControllerDelegate

extension ScanViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)

        var images: [UIImage] = []
        for i in 0..<scan.pageCount {
            images.append(scan.imageOfPage(at: i))
        }

        HapticManager.shared.scanCapture()
        processScannedImages(images)
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
        HapticManager.shared.error()
        showAlert(title: "Lỗi quét", message: error.localizedDescription)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ScanViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard !results.isEmpty else { return }

        var images: [UIImage] = []
        let group = DispatchGroup()

        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    images.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard !images.isEmpty else {
                self?.showAlert(title: "Lỗi", message: "Không thể đọc ảnh nào.")
                return
            }
            self?.processScannedImages(images)
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension ScanViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        processImportedURLs(urls)
    }

    private func processImportedURLs(_ urls: [URL]) {
        activityIndicator.startAnimating()
        setUIEnabled(false)

        Task {
            var pdfURLs: [URL] = []
            var imageURLs: [URL] = []

            for url in urls {
                let type = url.pathExtension.lowercased()
                if ["pdf"].contains(type) {
                    pdfURLs.append(url)
                } else if ["jpg", "jpeg", "png", "heic", "heif"].contains(type) {
                    imageURLs.append(url)
                }
            }

            // Copy PDF files directly
            var savedPDFURLs: [URL] = []
            for url in pdfURLs {
                do {
                    let savedURL = try ScanService.shared.importFile(from: url)
                    savedPDFURLs.append(savedURL)
                } catch {
                    print("Failed to import PDF: \(error)")
                }
            }

            // Convert images to PDF
            var images: [UIImage] = []
            for url in imageURLs {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
            }

            if !images.isEmpty {
                let pdfURL = try? ScanService.shared.savePDF(images: images, title: "Imported \(Date().formatted(date: .abbreviated, time: .shortened))")
                if let url = pdfURL { savedPDFURLs.append(url) }
            }

            // Create CDDocument entries
            let ctx = AppDelegate.shared.managedObjectContext
            for url in savedPDFURLs {
                let doc = CDDocument(context: ctx)
                doc.id = UUID()
                doc.title = url.deletingPathExtension().lastPathComponent
                doc.pdfFileName = url.lastPathComponent
                doc.pageCount = 1
                doc.createdAt = Date()
                doc.lastOpenedAt = Date()
                doc.isFavorite = false
                doc.isSecured = false
                doc.isProcessed = false
            }
            try? ctx.save()

            await MainActor.run {
                activityIndicator.stopAnimating()
                setUIEnabled(true)
                HapticManager.shared.success()

                if savedPDFURLs.isEmpty {
                    showAlert(title: "Lỗi", message: "Không thể nhập file nào.")
                } else {
                    showAlert(title: "Đã nhập!", message: "\(savedPDFURLs.count) file đã được thêm vào Thư viện.")
                }
            }
        }
    }
}

// MARK: - ScanPreviewViewControllerDelegate

extension ScanViewController: ScanPreviewViewControllerDelegate {
    func scanPreviewDidSave(images: [UIImage], title: String) {
        dismiss(animated: true) { [weak self] in
            self?.saveScannedDocument(images: images, title: title)
        }
    }

    func scanPreviewDidCancel() {
        dismiss(animated: true)
    }
}
