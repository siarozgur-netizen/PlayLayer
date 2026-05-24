import Foundation

enum WebPanelDefaults {
    struct Preset {
        let title: String
        let url: String
        let feedbackIcon: String
    }

    static let homeURL = "https://www.youtube.com"
    static let googleURL = "https://www.google.com"
    static let supportedHosts = ["youtube.com", "youtu.be"]
    static let youtubePreset = Preset(title: "YouTube", url: homeURL, feedbackIcon: "play.tv.fill")
    static let googlePreset = Preset(title: "Google", url: googleURL, feedbackIcon: "globe")

    static func searchURL(for query: String) -> String {
        youtubeSearchURL(for: query)
    }

    static func youtubeSearchURL(for query: String) -> String {
        let encoded = encodedQuery(for: query)
        return encoded.isEmpty
            ? homeURL
            : "\(homeURL)/results?search_query=\(encoded)"
    }

    static func googleSearchURL(for query: String) -> String {
        let encoded = encodedQuery(for: query)
        return encoded.isEmpty
            ? googleURL
            : "\(googleURL)/search?q=\(encoded)"
    }

    static func googleImageSearchURL(for query: String) -> String {
        let encoded = encodedQuery(for: query)
        return encoded.isEmpty
            ? googleURL
            : "\(googleURL)/search?tbm=isch&q=\(encoded)"
    }

    static func preset(named name: String) -> Preset? {
        switch name.lowercased() {
        case "google":
            return googlePreset
        case "youtube":
            return youtubePreset
        default:
            return nil
        }
    }

    static func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    static func isGoogleURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        return host.contains("google.")
    }

    private static func encodedQuery(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }

    static func title(for urlString: String) -> String {
        guard let host = URL(string: urlString)?.host?.lowercased() else {
            return youtubePreset.title
        }

        if host.contains("google.") {
            return googlePreset.title
        }

        if host.contains("youtube.com") || host.contains("youtu.be") {
            return youtubePreset.title
        }

        return host.replacingOccurrences(of: "www.", with: "").capitalized
    }
}
