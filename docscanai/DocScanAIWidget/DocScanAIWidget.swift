import WidgetKit
import SwiftUI

struct RecentDocumentsEntry: TimelineEntry {
    let date: Date
    let documents: [WidgetDocument]
}

struct WidgetDocument: Identifiable {
    let id: UUID
    let title: String
    let pageCount: Int
    let lastOpened: Date
}

struct RecentDocumentsProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentDocumentsEntry {
        RecentDocumentsEntry(date: Date(), documents: [
            WidgetDocument(id: UUID(), title: "Sample Document", pageCount: 1, lastOpened: Date())
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentDocumentsEntry) -> Void) {
        let entry = RecentDocumentsEntry(date: Date(), documents: loadRecentDocuments())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentDocumentsEntry>) -> Void) {
        let entry = RecentDocumentsEntry(date: Date(), documents: loadRecentDocuments())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadRecentDocuments() -> [WidgetDocument] {
        let sharedDefaults = UserDefaults(suiteName: "group.com.docscanai.app")
        guard let data = sharedDefaults?.data(forKey: "recentDocuments"),
              let decoded = try? JSONDecoder().decode([WidgetDocumentData].self, from: data) else {
            return []
        }
        return decoded.map { WidgetDocument(id: $0.id, title: $0.title, pageCount: $0.pageCount, lastOpened: $0.lastOpened) }
    }
}

struct WidgetDocumentData: Codable {
    let id: UUID
    let title: String
    let pageCount: Int
    let lastOpened: Date
}

struct RecentDocumentsWidgetView: View {
    var entry: RecentDocumentsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            mediumWidget
        }
    }

    @ViewBuilder
    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.viewfinder.fill")
                    .foregroundStyle(.blue)
                Text("DocScan AI")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            if let doc = entry.documents.first {
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    Text("\(doc.pageCount) trang")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Không có tài liệu gần đây")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    @ViewBuilder
    var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.viewfinder.fill")
                    .foregroundStyle(.blue)
                Text("Tài liệu gần đây")
                    .font(.headline)
                Spacer()
                Image(systemName: "viewfinder")
                    .foregroundStyle(.secondary)
            }

            if entry.documents.isEmpty {
                Text("Chưa có tài liệu nào. Mở app để bắt đầu quét!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.documents.prefix(3)) { doc in
                    Link(destination: URL(string: "docscanai://open?id=\(doc.id.uuidString)")!) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                                Text("\(doc.pageCount) trang • \(doc.lastOpened.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if doc.id != entry.documents.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

@main
struct DocScanAIWidget: Widget {
    let kind: String = "DocScanAIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentDocumentsProvider()) { entry in
            RecentDocumentsWidgetView(entry: entry)
        }
        .configurationDisplayName("Tài liệu gần đây")
        .description("Xem nhanh các tài liệu đã quét gần đây.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}