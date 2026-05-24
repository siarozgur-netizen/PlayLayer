import Foundation

enum CommandIntent: Equatable {
    case unknown
    case openPreset(name: String)
    case openURL(URL)
    case youtubeSearch(query: String)
    case imageSearch(query: String)
    case webSearch(query: String)
}

struct CommandParser {
    private static let presetAliases: [String: String] = [
        "google": "google",
        "open google": "google",
        "youtube": "youtube",
        "open youtube": "youtube",
    ]

    private static let videoIntentKeywords = [
        "youtube",
        "yt",
        "video",
        "tutorial",
        "guide",
        "walkthrough",
        "how to",
    ]

    private static let imageIntentKeywords = [
        "image",
        "images",
        "picture",
        "pictures",
        "photo",
        "photos",
        "wallpaper",
        "wallpapers",
    ]

    private static let leadingFillerPhrases = [
        "search for",
        "show me",
        "find me",
        "look up",
        "open",
        "search",
        "show",
        "find",
        "google",
        "youtube",
        "yt",
    ]

    private static let platformTokens: Set<String> = [
        "google",
        "youtube",
        "yt",
    ]

    private static let genericImageBoundaryTokens: Set<String> = [
        "image",
        "images",
        "picture",
        "pictures",
        "photo",
        "photos",
    ]

    static func parse(_ rawInput: String) -> CommandIntent {
        let collapsedInput = collapseWhitespace(rawInput.trimmingCharacters(in: .whitespacesAndNewlines))
        let normalized = normalize(rawInput)
        guard !normalized.isEmpty else {
            return .unknown
        }

        if let directURL = url(from: collapsedInput) {
            return .openURL(directURL)
        }

        if let presetName = presetAliases[normalized] {
            return .openPreset(name: presetName)
        }

        if let cleanedURL = url(from: stripLeadingFillerPhrasesPreservingCase(collapsedInput)) {
            return .openURL(cleanedURL)
        }

        let hasVideoIntent = containsIntentKeyword(normalized, keywords: videoIntentKeywords)
        let hasImageIntent = containsIntentKeyword(normalized, keywords: imageIntentKeywords)
        let cleanedQuery = cleanQuery(normalized, isImageIntent: hasImageIntent)

        guard !cleanedQuery.isEmpty else {
            return .unknown
        }

        if hasVideoIntent {
            return .youtubeSearch(query: cleanedQuery)
        }

        if hasImageIntent {
            return .imageSearch(query: cleanedQuery)
        }

        return .webSearch(query: cleanedQuery)
    }

    static func normalize(_ input: String) -> String {
        collapseWhitespace(
            input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        )
    }

    static func cleanQuery(_ normalizedInput: String, isImageIntent: Bool) -> String {
        var query = normalizedInput

        for phrase in leadingFillerPhrases.sorted(by: { $0.count > $1.count }) {
            while query == phrase || query.hasPrefix("\(phrase) ") {
                query = String(query.dropFirst(phrase.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        var tokens = query.split(separator: " ").map(String.init)
        tokens.removeAll { platformTokens.contains($0) }

        if isImageIntent {
            while let first = tokens.first, genericImageBoundaryTokens.contains(first) {
                tokens.removeFirst()
            }

            while let last = tokens.last, genericImageBoundaryTokens.contains(last) {
                tokens.removeLast()
            }
        }

        return tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func url(from input: String) -> URL? {
        guard !input.contains(" ") else {
            return nil
        }

        if let url = URL(string: input), let scheme = url.scheme, let host = url.host, !scheme.isEmpty, !host.isEmpty {
            return url
        }

        if input.hasPrefix("www."), let url = URL(string: "https://\(input)"), url.host != nil {
            return url
        }

        return nil
    }

    private static func collapseWhitespace(_ input: String) -> String {
        input
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func stripLeadingFillerPhrasesPreservingCase(_ input: String) -> String {
        var candidate = input.trimmingCharacters(in: .whitespacesAndNewlines)

        for phrase in leadingFillerPhrases.sorted(by: { $0.count > $1.count }) {
            while candidate.lowercased() == phrase || candidate.lowercased().hasPrefix("\(phrase) ") {
                candidate = String(candidate.dropFirst(phrase.count)).trimmingCharacters(in: .whitespaces)
            }
        }

        return candidate
    }

    private static func containsIntentKeyword(_ normalizedInput: String, keywords: [String]) -> Bool {
        let tokens = Set(normalizedInput.split(separator: " ").map(String.init))

        return keywords.contains { keyword in
            if keyword.contains(" ") {
                return normalizedInput.contains(keyword)
            }

            return tokens.contains(keyword)
        }
    }
}
