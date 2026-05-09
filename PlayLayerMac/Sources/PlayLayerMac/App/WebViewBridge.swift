import Foundation
import WebKit

@MainActor
final class WebViewBridge: ObservableObject {
    weak var webView: WKWebView?
    var onNavigationStateChanged: ((Bool, String) -> Void)?
    var onOverlayFullscreenRequested: (() -> Void)?

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func navigate(to urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        webView?.load(URLRequest(url: url))
    }

    func searchYouTube(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let target = encoded.isEmpty
            ? "https://www.youtube.com"
            : "https://www.youtube.com/results?search_query=\(encoded)"
        navigate(to: target)
    }

    func isVideoURL(_ url: URL) -> Bool {
        guard isYouTubeHost(url) else {
            return false
        }

        return url.path == "/watch" || url.path.hasPrefix("/shorts/")
    }

    func handleNavigationFinished(in webView: WKWebView) {
        guard let url = webView.url else {
            onNavigationStateChanged?(false, "")
            return
        }

        let isVideoMode = isVideoURL(url)
        onNavigationStateChanged?(isVideoMode, url.absoluteString)
    }

    func requestOverlayFullscreenToggle() {
        onOverlayFullscreenRequested?()
    }

    func navigateHome() {
        navigate(to: "https://www.youtube.com")
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

    private func isYouTubeHost(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }

        return host.contains("youtube.com") || host.contains("youtu.be")
    }
}
