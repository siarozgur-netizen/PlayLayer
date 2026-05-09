import Foundation

struct AppConfig: Codable {
    var opacity: Double
    var lastURL: String
    var interactModeEnabled: Bool
    var overlayFullscreenEnabled: Bool

    static let `default` = AppConfig(
        opacity: 1.0,
        lastURL: "https://www.youtube.com",
        interactModeEnabled: true,
        overlayFullscreenEnabled: false
    )
}
