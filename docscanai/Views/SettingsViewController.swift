import UIKit
import StoreKit

/// Settings view controller.
final class SettingsViewController: UIViewController {

    private var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Cài đặt"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDelegate & DataSource

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    enum Section: Int, CaseIterable {
        case subscription
        case aiConfig
        case security
        case preferences
        case about

        var title: String {
            switch self {
            case .subscription: return "Gói Premium"
            case .aiConfig: return "AI Configuration"
            case .security: return "Bảo mật"
            case .preferences: return "Tùy chỉnh"
            case .about: return "Về ứng dụng"
            }
        }

        var rows: [String] {
            switch self {
            case .subscription: return ["Quản lý gói Premium"]
            case .aiConfig: return ["API Key (Claude)", "API Key (OpenAI)"]
            case .security: return ["Face ID khóa ứng dụng"]
            case .preferences: return ["Haptic Feedback", "Ngôn ngữ OCR"]
            case .about: return ["Phiên bản", "iOS tối thiểu"]
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Section(rawValue: section)?.rows.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        guard let section = Section(rawValue: indexPath.section) else { return cell }

        cell.textLabel?.text = section.rows[indexPath.row]

        switch section {
        case .subscription:
            if SubscriptionManager.shared.hasPremiumAccess() {
                cell.detailTextLabel?.text = SubscriptionManager.shared.status.statusText
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Nâng cấp Premium"
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemBlue
            }

        case .aiConfig:
            cell.accessoryType = .disclosureIndicator
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = KeychainHelper.shared.exists(.claudeAPIKey) ? "Đã cài đặt" : "Đã cài đặt"
            } else {
                cell.detailTextLabel?.text = KeychainHelper.shared.exists(.openaiAPIKey) ? "Đã cài đặt" : "Chưa cài đặt"
            }

        case .security:
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: "appLockEnabled")
            toggle.addTarget(self, action: #selector(appLockToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .preferences:
            if indexPath.row == 0 {
                let toggle = UISwitch()
                toggle.isOn = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
                toggle.addTarget(self, action: #selector(hapticToggled(_:)), for: .valueChanged)
                cell.accessoryView = toggle
                cell.selectionStyle = .none
            } else {
                cell.accessoryType = .disclosureIndicator
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "defaultLanguage") ?? "vi"
            }

        case .about:
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.detailTextLabel?.text = "1.0.0"
            } else {
                cell.detailTextLabel?.text = "iOS 16.4+"
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .subscription:
            showSubscriptionVC()
        case .aiConfig:
            if indexPath.row == 0 {
                showAPIKeyAlert(provider: "Claude", keyName: "claudeAPIKey", url: "console.anthropic.com")
            } else {
                showAPIKeyAlert(provider: "OpenAI", keyName: "openaiAPIKey", url: "platform.openai.com")
            }
        case .preferences:
            if indexPath.row == 1 {
                showLanguagePicker()
            }
        default:
            break
        }
    }

    private func showAPIKeyAlert(provider: String, keyName: String, url: String) {
        let placeholder = provider == "Claude" ? "sk-ant-..." : "sk-proj-..."
        let keychainKey: KeychainHelper.Key = provider == "Claude" ? .claudeAPIKey : .openaiAPIKey
        let alert = UIAlertController(title: "\(provider) API Key", message: "Nhập API key từ \(url)", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.isSecureTextEntry = true
            tf.text = KeychainHelper.shared.read(keychainKey)
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            if let key = alert.textFields?.first?.text {
                KeychainHelper.shared.save(key, for: keychainKey)
                HapticManager.shared.success()
                self?.tableView.reloadData()
            }
        })
        present(alert, animated: true)
    }

    private func showLanguagePicker() {
        let alert = UIAlertController(title: "Ngôn ngữ OCR", message: nil, preferredStyle: .actionSheet)
        let languages = [("vi", "Tiếng Việt"), ("en", "English"), ("zh", "中文")]
        for (code, name) in languages {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                UserDefaults.standard.set(code, forKey: "defaultLanguage")
                self?.tableView.reloadData()
                HapticManager.shared.success()
            })
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func appLockToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "appLockEnabled")
        HapticManager.shared.lightImpact()
    }

    @objc private func hapticToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "hapticFeedbackEnabled")
        HapticManager.shared.lightImpact()
    }

    private func showSubscriptionVC() {
        let paywall = SubscriptionViewController()
        paywall.modalPresentationStyle = .pageSheet
        if let sheet = paywall.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(paywall, animated: true)
    }
}