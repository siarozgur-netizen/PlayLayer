import Foundation
import WebKit

@MainActor
final class WebPanelBridge: ObservableObject {
    weak var webView: WKWebView?
    var onNavigationStateChanged: ((Bool, String) -> Void)?
    var onOverlayFullscreenRequested: (() -> Void)?
    var initialURLString = WebPanelDefaults.homeURL
    private(set) var currentURLString = WebPanelDefaults.homeURL

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func navigate(to urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        currentURLString = urlString
        webView?.load(URLRequest(url: url))
    }

    func searchCurrentContent(query: String) {
        navigate(to: WebPanelDefaults.searchURL(for: query))
    }

    func isPanelVideoURL(_ url: URL) -> Bool {
        guard isSupportedHost(url) else {
            return false
        }

        return url.path == "/watch" || url.path.hasPrefix("/shorts/")
    }

    func handleNavigationFinished(in webView: WKWebView) {
        guard let url = webView.url else {
            onNavigationStateChanged?(false, "")
            return
        }

        currentURLString = url.absoluteString
        let isVideoMode = isPanelVideoURL(url)
        onNavigationStateChanged?(isVideoMode, url.absoluteString)
    }

    func requestOverlayFullscreenToggle() {
        onOverlayFullscreenRequested?()
    }

    func navigateHome() {
        navigate(to: WebPanelDefaults.homeURL)
    }

    func reload() {
        webView?.reload()
    }

    func togglePlayback() {
        webView?.evaluateJavaScript(
            """
            (() => {
              const video = document.querySelector('video');
              if (!video) {
                return false;
              }

              if (video.paused) {
                video.play().catch(() => {});
              } else {
                video.pause();
              }

              return video.paused ? 'paused' : 'playing';
            })();
            """
        )
    }

    func seek(by seconds: Double) {
        webView?.evaluateJavaScript(
            """
            (() => {
              const video = document.querySelector('video');
              if (!video) {
                return false;
              }

              const duration = Number.isFinite(video.duration) ? video.duration : video.currentTime + \(abs(seconds));
              video.currentTime = Math.min(Math.max(video.currentTime + \(seconds), 0), duration);
              return true;
            })();
            """
        )
    }

    private func isSupportedHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        return WebPanelDefaults.supportedHosts.contains { host.contains($0) }
    }
}
