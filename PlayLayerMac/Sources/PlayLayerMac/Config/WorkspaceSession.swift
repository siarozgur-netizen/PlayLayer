import Foundation

struct WorkspaceSession: Codable {
    var webPanels: [RestorableWebPanelSession]
    var imagePanels: [RestorableFilePanelSession]
    var pdfPanels: [RestorableFilePanelSession]

    private enum CodingKeys: String, CodingKey {
        case webPanels
        case webPanel
        case imagePanels
        case pdfPanels
    }

    init(webPanels: [RestorableWebPanelSession], imagePanels: [RestorableFilePanelSession], pdfPanels: [RestorableFilePanelSession]) {
        self.webPanels = webPanels
        self.imagePanels = imagePanels
        self.pdfPanels = pdfPanels
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let webPanels = try container.decodeIfPresent([RestorableWebPanelSession].self, forKey: .webPanels) {
            self.webPanels = webPanels
        } else if let legacyWebPanel = try container.decodeIfPresent(RestorableWebPanelSession.self, forKey: .webPanel) {
            self.webPanels = [legacyWebPanel]
        } else {
            self.webPanels = []
        }

        self.imagePanels = try container.decode([RestorableFilePanelSession].self, forKey: .imagePanels)
        self.pdfPanels = try container.decode([RestorableFilePanelSession].self, forKey: .pdfPanels)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(webPanels, forKey: .webPanels)
        try container.encode(imagePanels, forKey: .imagePanels)
        try container.encode(pdfPanels, forKey: .pdfPanels)
    }
}

struct RestorableWebPanelSession: Codable {
    var url: String
    var homeURL: String
    var frame: PanelFrameRecord
    var opacity: Double

    private enum CodingKeys: String, CodingKey {
        case url
        case homeURL
        case frame
        case opacity
    }

    init(url: String, homeURL: String, frame: PanelFrameRecord, opacity: Double) {
        self.url = url
        self.homeURL = homeURL
        self.frame = frame
        self.opacity = opacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(String.self, forKey: .url)
        self.homeURL = try container.decodeIfPresent(String.self, forKey: .homeURL) ?? WebPanelDefaults.homeURL
        self.frame = try container.decode(PanelFrameRecord.self, forKey: .frame)
        self.opacity = try container.decode(Double.self, forKey: .opacity)
    }
}

struct RestorableFilePanelSession: Codable {
    var path: String
    var frame: PanelFrameRecord
    var opacity: Double
}

struct PanelFrameRecord: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(frame: CGRect) {
        self.x = frame.origin.x
        self.y = frame.origin.y
        self.width = frame.size.width
        self.height = frame.size.height
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}
