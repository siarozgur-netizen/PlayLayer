import Foundation

@MainActor
final class PanelRuntimeState: ObservableObject {
    @Published var searchText: String
    @Published var isVideoMode: Bool
    @Published var isPlaybackLocked: Bool
    @Published var isOverlayFullscreen: Bool
    @Published var actionFeedback: ActionFeedback?
    @Published var theaterTransitionID: Int
    let webPanelBridge: WebPanelBridge

    init(searchText: String = "", isOverlayFullscreen: Bool = false) {
        self.searchText = searchText
        self.isVideoMode = false
        self.isPlaybackLocked = false
        self.isOverlayFullscreen = isOverlayFullscreen
        self.actionFeedback = nil
        self.theaterTransitionID = 0
        self.webPanelBridge = WebPanelBridge()
        self.webPanelBridge.onNavigationStateChanged = { [weak self] isVideoMode, urlString in
            self?.isVideoMode = isVideoMode
            if !isVideoMode && self?.isPlaybackLocked != true {
                self?.searchText = ""
            }
            _ = urlString
        }
        self.webPanelBridge.onOverlayFullscreenRequested = { [weak self] in
            self?.isOverlayFullscreen.toggle()
        }
    }

    func showActionFeedback(icon: String, title: String) {
        actionFeedback = ActionFeedback(icon: icon, title: title)
    }

    func requestTheaterTransition() {
        theaterTransitionID += 1
    }
}

struct ActionFeedback: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
}
