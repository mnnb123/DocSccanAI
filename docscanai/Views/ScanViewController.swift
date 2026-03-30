import UIKit
import VisionKit
import CoreData
import PhotosUI

/// Scan view controller using VisionKit.
final class ScanViewController: UIViewController {

    private var scanButton: UIButton!
    private var importButton: UIButton!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var iconImageView: UIImageView!
    private var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "DocScan AI"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        // Icon
        iconImageView = UIImageView(image: UIImage(systemName: "doc.viewfinder"))
        iconImageView.tintColor = .secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)

        // Title
        titleLabel = UILabel()
        titleLabel.text = "Quét tài liệu"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Subtitle
        subtitleLabel = UILabel()
        subtitleLabel.text = "Chụp ảnh tài liệu bằng camera\nhoặc nhập từ thư viện ảnh"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Scan Button
        scanButton = UIButton(type: .system)
        var scanConfig = UIButton.Configuration.filled()
        scanConfig.title = "Quét ngay"
        scanConfig.image = UIImage(systemName: "viewfinder")
        scanConfig.imagePadding = 8
        scanConfig.baseBackgroundColor = .systemBlue
        scanConfig.baseForegroundColor = .white
        scanConfig.cornerStyle = .large
        scanButton.configuration = scanConfig
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(openScanner), for: .touchUpInside)
        view.addSubview(scanButton)

        // Import Button
        importButton = UIButton(type: .system)
        var importConfig = UIButton.Configuration.filled()
        importConfig.title = "Nhập từ Photos"
        importConfig.image = UIImage(systemName: "photo.on.rectangle")
        importConfig.imagePadding = 8
        importConfig.baseBackgroundColor = .secondarySystemGroupedBackground
        importConfig.baseForegroundColor = .label
        importConfig.cornerStyle = .large
        importButton.configuration = importConfig
        importButton.translatesAutoresizingMaskIntoConstraints = false
        importButton.addTarget(self, action: #selector(openPhotoPicker), for: .touchUpInside)
        view.addSubview(importButton)

        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
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

            scanButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            scanButton.heightAnchor.constraint(equalToConstant: 50),

            importButton.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 16),
            importButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            importButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func openScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            showAlert(title: "Không hỗ trợ", message: "Thiết bị không hỗ trợ quét tài liệu")
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
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func processScannedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }

        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false

        Task {
            do {
                // Save as PDF
                let title = "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
                let pdfURL = try ScanService.shared.savePDF(images: images, title: title)

                // Generate thumbnail
                _ = ScanService.shared.generateThumbnail(for: pdfURL)

                // Save to Core Data
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

                HapticManager.shared.success()

                await MainActor.run {
                    activityIndicator.stopAnimating()
                    view.isUserInteractionEnabled = true
                    showAlert(title: "Thành công", message: "Tài liệu đã được lưu. Vào Thư viện để xem.")
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    view.isUserInteractionEnabled = true
                    HapticManager.shared.error()
                    showAlert(title: "Lỗi", message: error.localizedDescription)
                }
            }
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
        processScannedImages(images)
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
        showAlert(title: "Lỗi quét", message: error.localizedDescription)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ScanViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Lỗi", message: "Không thể đọc ảnh")
                }
                return
            }

            DispatchQueue.main.async {
                self?.processScannedImages([image])
            }
        }
    }
}
