import Foundation

struct CommandBarAction: Identifiable {
    let id = UUID()
    let title: String
    let keywords: [String]
    let shortcutHint: String?
    let handler: () -> Void

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return true }

        if title.lowercased().contains(normalizedQuery) {
            return true
        }

        return keywords.contains { $0.lowercased().contains(normalizedQuery) }
    }
}
