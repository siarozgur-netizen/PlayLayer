import Foundation

struct WorkspaceSession: Codable {
    var webPanel: RestorableWebPanelSession?
    var imagePanels: [RestorableFilePanelSession]
    var pdfPanels: [RestorableFilePanelSession]
}

struct RestorableWebPanelSession: Codable {
    var url: String
    var frame: PanelFrameRecord
    var opacity: Double
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
