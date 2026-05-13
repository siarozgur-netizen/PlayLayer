import Foundation

struct AppConfig: Codable {
    var opacity: Double
    var panelHomeURL: String
    var interactModeEnabled: Bool
    var overlayFullscreenEnabled: Bool
    var panelFrameX: Double?
    var panelFrameY: Double?
    var panelFrameWidth: Double?
    var panelFrameHeight: Double?
    var workspaceSession: WorkspaceSession?

    private enum CodingKeys: String, CodingKey {
        case opacity
        case panelHomeURL
        case lastURL
        case interactModeEnabled
        case overlayFullscreenEnabled
        case panelFrameX
        case panelFrameY
        case panelFrameWidth
        case panelFrameHeight
        case workspaceSession
    }

    static let `default` = AppConfig(
        opacity: PanelDefaults.opacity,
        panelHomeURL: WebPanelDefaults.homeURL,
        interactModeEnabled: PanelDefaults.interactModeEnabled,
        overlayFullscreenEnabled: PanelDefaults.overlayFullscreenEnabled
    )

    init(
        opacity: Double,
        panelHomeURL: String,
        interactModeEnabled: Bool,
        overlayFullscreenEnabled: Bool,
        panelFrameX: Double? = nil,
        panelFrameY: Double? = nil,
        panelFrameWidth: Double? = nil,
        panelFrameHeight: Double? = nil,
        workspaceSession: WorkspaceSession? = nil
    ) {
        self.opacity = opacity
        self.panelHomeURL = panelHomeURL
        self.interactModeEnabled = interactModeEnabled
        self.overlayFullscreenEnabled = overlayFullscreenEnabled
        self.panelFrameX = panelFrameX
        self.panelFrameY = panelFrameY
        self.panelFrameWidth = panelFrameWidth
        self.panelFrameHeight = panelFrameHeight
        self.workspaceSession = workspaceSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        opacity = try container.decode(Double.self, forKey: .opacity)
        panelHomeURL = try container.decodeIfPresent(String.self, forKey: .panelHomeURL)
            ?? container.decodeIfPresent(String.self, forKey: .lastURL)
            ?? WebPanelDefaults.homeURL
        interactModeEnabled = try container.decode(Bool.self, forKey: .interactModeEnabled)
        overlayFullscreenEnabled = try container.decode(Bool.self, forKey: .overlayFullscreenEnabled)
        panelFrameX = try container.decodeIfPresent(Double.self, forKey: .panelFrameX)
        panelFrameY = try container.decodeIfPresent(Double.self, forKey: .panelFrameY)
        panelFrameWidth = try container.decodeIfPresent(Double.self, forKey: .panelFrameWidth)
        panelFrameHeight = try container.decodeIfPresent(Double.self, forKey: .panelFrameHeight)
        workspaceSession = try container.decodeIfPresent(WorkspaceSession.self, forKey: .workspaceSession)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(panelHomeURL, forKey: .panelHomeURL)
        try container.encode(interactModeEnabled, forKey: .interactModeEnabled)
        try container.encode(overlayFullscreenEnabled, forKey: .overlayFullscreenEnabled)
        try container.encodeIfPresent(panelFrameX, forKey: .panelFrameX)
        try container.encodeIfPresent(panelFrameY, forKey: .panelFrameY)
        try container.encodeIfPresent(panelFrameWidth, forKey: .panelFrameWidth)
        try container.encodeIfPresent(panelFrameHeight, forKey: .panelFrameHeight)
        try container.encodeIfPresent(workspaceSession, forKey: .workspaceSession)
    }
}
