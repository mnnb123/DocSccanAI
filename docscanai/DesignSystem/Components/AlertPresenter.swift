import UIKit

/// Centralized alert presenter - eliminates duplicate showAlert() in every ViewController.
final class AlertPresenter {

    // MARK: - Singleton

    static let shared = AlertPresenter()

    private init() {}

    // MARK: - Simple Alert

    func show(
        on presenter: UIViewController,
        title: String,
        message: String,
        buttonTitle: String = "OK",
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { _ in
            completion?()
        })
        presenter.present(alert, animated: true)
    }

    // MARK: - Confirmation Alert

    func confirm(
        on presenter: UIViewController,
        title: String,
        message: String,
        confirmTitle: String = "Xác nhận",
        cancelTitle: String = "Hủy",
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        presenter.present(alert, animated: true)
    }

    // MARK: - Text Input Alert

    func textInput(
        on presenter: UIViewController,
        title: String,
        message: String?,
        placeholder: String?,
        initialText: String? = nil,
        isSecure: Bool = false,
        confirmTitle: String = "OK",
        onConfirm: @escaping (String?) -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = placeholder
            tf.text = initialText
            tf.isSecureTextEntry = isSecure
        }
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm(alert.textFields?.first?.text)
        })
        presenter.present(alert, animated: true)
    }

    // MARK: - Error Alert

    func error(
        on presenter: UIViewController,
        title: String = "Lỗi",
        message: String,
        completion: (() -> Void)? = nil
    ) {
        show(on: presenter, title: title, message: message, buttonTitle: "Đóng", completion: completion)
    }

    // MARK: - Success Alert

    func success(
        on presenter: UIViewController,
        message: String,
        completion: (() -> Void)? = nil
    ) {
        show(on: presenter, title: "Thành công!", message: message, buttonTitle: "OK", completion: completion)
    }

    // MARK: - Action Sheet

    func actionSheet(
        on presenter: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [(title: String, style: UIAlertAction.Style, handler: () -> Void)]
    ) {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions {
            sheet.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler()
            })
        }
        sheet.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        presenter.present(sheet, animated: true)
    }
}
