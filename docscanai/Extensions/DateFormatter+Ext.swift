import Foundation

extension Date {
    /// "15 thg 3, 2026" - Vietnamese date format
    var formattedVietnamese: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "d 'thg' M, yyyy"
        return formatter.string(from: self)
    }

    /// "15/03/2026" - Short date
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    /// "15 thg 3" - Month + day only
    var formattedMonthDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "d 'thg' M"
        return formatter.string(from: self)
    }

    /// Relative time: "2 phút trước", "Hôm qua", "3 ngày trước"
    var relativeTimeVietnamese: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// "15/03/2026 14:30"
    var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
