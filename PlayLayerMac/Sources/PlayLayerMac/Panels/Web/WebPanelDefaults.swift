import Foundation

enum WebPanelDefaults {
    static let homeURL = "https://www.youtube.com"
    static let supportedHosts = ["youtube.com", "youtu.be"]

    static func searchURL(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return encoded.isEmpty
            ? homeURL
            : "\(homeURL)/results?search_query=\(encoded)"
    }
}
