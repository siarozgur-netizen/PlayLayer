import SwiftUI
import WebKit

struct OverlayRootView: View {
    @ObservedObject var runtimeState: OverlayRuntimeState
    @State private var showsGuide = true
    @State private var hideGuideWorkItem: DispatchWorkItem?
    @State private var visibleFeedback: ActionFeedback?
    @State private var hideFeedbackWorkItem: DispatchWorkItem?
    @State private var showsTheaterTransition = false
    @State private var hideTheaterTransitionWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            WebContainerView(bridge: runtimeState.webViewBridge)
                .background(Color.black)

            ZStack(alignment: .topLeading) {
                if showsGuide {
                    HotkeyGuideCard()
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
                        .allowsHitTesting(false)
                }
            }

            if let visibleFeedback {
                ActionFeedbackView(feedback: visibleFeedback)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .allowsHitTesting(false)
            }

            if showsTheaterTransition {
                TheaterTransitionView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .allowsHitTesting(false)
            }
        }
        .background(Color.black)
        .animation(.easeOut(duration: 0.16), value: showsGuide)
        .animation(.easeOut(duration: 0.14), value: visibleFeedback)
        .animation(.easeOut(duration: 0.18), value: showsTheaterTransition)
        .onAppear {
            showGuideTemporarily()
        }
        .onChange(of: runtimeState.guideRequestID) { _ in
            showGuideTemporarily()
        }
        .onChange(of: runtimeState.actionFeedback) { feedback in
            showFeedbackTemporarily(feedback)
        }
        .onChange(of: runtimeState.theaterTransitionID) { _ in
            showTheaterTransition()
        }
        .onDisappear {
            hideGuideWorkItem?.cancel()
            hideGuideWorkItem = nil
            hideFeedbackWorkItem?.cancel()
            hideFeedbackWorkItem = nil
            hideTheaterTransitionWorkItem?.cancel()
            hideTheaterTransitionWorkItem = nil
        }
    }

    private func showGuideTemporarily() {
        hideGuideWorkItem?.cancel()
        showsGuide = true

        let workItem = DispatchWorkItem {
            showsGuide = false
        }

        hideGuideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: workItem)
    }

    private func showFeedbackTemporarily(_ feedback: ActionFeedback?) {
        hideFeedbackWorkItem?.cancel()
        visibleFeedback = feedback

        guard feedback != nil else {
            return
        }

        let workItem = DispatchWorkItem {
            visibleFeedback = nil
        }

        hideFeedbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: workItem)
    }

    private func showTheaterTransition() {
        hideTheaterTransitionWorkItem?.cancel()
        showsTheaterTransition = true

        let workItem = DispatchWorkItem {
            showsTheaterTransition = false
        }

        hideTheaterTransitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: workItem)
    }
}

private struct TheaterTransitionView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.30, green: 0.78, blue: 1.0).opacity(0.95),
                            Color.white.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            HStack(spacing: 10) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(red: 0.45, green: 0.84, blue: 1.0))

                Text("THEATER")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.black.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(12)
    }
}

private struct ActionFeedbackView: View {
    let feedback: ActionFeedback

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(feedback.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.38), radius: 20, x: 0, y: 10)
    }
}

private struct HotkeyGuideCard: View {
    private let primaryItems: [HotkeyGuideItem] = [
        HotkeyGuideItem(keys: "Ctrl + Option + O", label: "Hide / Show"),
        HotkeyGuideItem(keys: "Ctrl + Option + H", label: "Home"),
        HotkeyGuideItem(keys: "Ctrl + Option + T", label: "Exit Theater"),
        HotkeyGuideItem(keys: "Ctrl + Option + C", label: "Guide")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.45, green: 0.78, blue: 1.0))

                Text("PlayLayer Controls")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(primaryItems) { item in
                    HStack(spacing: 10) {
                        Text(item.keys)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        Text(item.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                    }
                }
            }

            Text("Video opens in Theater + PASS automatically.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.58))
        }
        .padding(14)
        .frame(width: 286, alignment: .leading)
        .background(.black.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.38), radius: 20, x: 0, y: 10)
    }
}

private struct HotkeyGuideItem: Identifiable {
    let id = UUID()
    let keys: String
    let label: String
}

struct WebContainerView: NSViewRepresentable {
    let bridge: WebViewBridge

    func makeCoordinator() -> Coordinator {
        Coordinator(bridge: bridge)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.isElementFullscreenEnabled = true
        if #available(macOS 11.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        configuration.userContentController.add(context.coordinator, name: "playLayerRoute")
        configuration.userContentController.add(context.coordinator, name: "playLayerCommand")
        configuration.userContentController.addUserScript(Self.routeObserverScript)
        configuration.userContentController.addUserScript(Self.fullscreenInterceptorScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.black.cgColor
        webView.setValue(true, forKey: "drawsBackground")
        if #available(macOS 15.0, *) {
            webView.underPageBackgroundColor = .black
        }
        bridge.attach(webView)
        webView.load(URLRequest(url: URL(string: "https://www.youtube.com")!))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        _ = nsView
        _ = context
    }

    private static let routeObserverScript = WKUserScript(
        source: """
        (() => {
          if (window.__playLayerRouteObserverInstalled) {
            return;
          }
          window.__playLayerRouteObserverInstalled = true;

          const notify = () => {
            try {
              window.webkit.messageHandlers.playLayerRoute.postMessage(window.location.href);
            } catch (_) {
            }
          };

          const wrap = (fn) => function(...args) {
            const result = fn.apply(this, args);
            setTimeout(notify, 0);
            return result;
          };

          history.pushState = wrap(history.pushState);
          history.replaceState = wrap(history.replaceState);
          window.addEventListener('popstate', notify);
          window.addEventListener('hashchange', notify);
          document.addEventListener('yt-navigate-finish', notify, true);
          document.addEventListener('click', () => setTimeout(notify, 0), true);
          notify();
        })();
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )

    private static let fullscreenInterceptorScript = WKUserScript(
        source: """
        (() => {
          if (window.__playLayerFullscreenInterceptorInstalled) {
            return;
          }
          window.__playLayerFullscreenInterceptorInstalled = true;

          document.addEventListener('click', (event) => {
            const target = event.target;
            if (!(target instanceof Element)) {
              return;
            }

            const fullscreenButton = target.closest('.ytp-fullscreen-button');
            if (!fullscreenButton) {
              return;
            }

            event.preventDefault();
            event.stopPropagation();
            event.stopImmediatePropagation();

            try {
              window.webkit.messageHandlers.playLayerCommand.postMessage('toggleOverlayFullscreen');
            } catch (_) {
            }
          }, true);
        })();
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
    )

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        private let bridge: WebViewBridge

        init(bridge: WebViewBridge) {
            self.bridge = bridge
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            _ = navigation
            bridge.handleNavigationFinished(in: webView)
            applyYouTubeChromeSuppression(to: webView)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            _ = configuration
            _ = windowFeatures

            if let targetURL = navigationAction.request.url {
                bridge.navigate(to: targetURL.absoluteString)
            }

            return nil
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            _ = userContentController

            guard
                let body = message.body as? String
            else {
                return
            }

            if message.name == "playLayerCommand", body == "toggleOverlayFullscreen" {
                bridge.requestOverlayFullscreenToggle()
                return
            }

            guard
                message.name == "playLayerRoute",
                let url = URL(string: body)
            else {
                return
            }

            let isVideoMode = bridge.isVideoURL(url)
            bridge.onNavigationStateChanged?(isVideoMode, body)

            if let webView = bridge.webView {
                applyYouTubeChromeSuppression(to: webView)
            }
        }

        private func applyYouTubeChromeSuppression(to webView: WKWebView) {
            let isVideoPage = webView.url.map { bridge.isVideoURL($0) } ?? false
            let script = isVideoPage
                ? """
                (() => {
                  document.documentElement.style.background = '#000';
                  document.body.style.background = '#000';
                  document.body.style.margin = '0';

                  const styleId = 'playlayer-watch-style';
                  let style = document.getElementById(styleId);
                  if (!style) {
                    style = document.createElement('style');
                    style.id = styleId;
                    document.head.appendChild(style);
                  }

                  style.textContent = `
                    html, body, ytd-app, #content, #page-manager, ytd-watch-flexy {
                      margin: 0 !important;
                      padding: 0 !important;
                      background: #000 !important;
                      overflow: hidden !important;
                    }

                    #masthead,
                    #masthead-container,
                    ytd-masthead,
                    ytd-mini-guide-renderer,
                    ytd-guide-renderer,
                    #guide,
                    #guide-content,
                    #secondary,
                    #secondary-inner,
                    #below,
                    #related,
                    #comments,
                    #chat-container,
                    #header,
                    #endscreen,
                    #playlist,
                    ytd-merch-shelf-renderer,
                    ytd-watch-metadata,
                    tp-yt-app-drawer,
                    .ytp-fullscreen-button,
                    .ytp-size-button,
                    .ytp-youtube-button,
                    .ytp-chrome-top,
                    .ytp-gradient-top,
                    .ytp-title,
                    .iv-branding,
                    .annotation {
                      display: none !important;
                      opacity: 0 !important;
                      visibility: hidden !important;
                      pointer-events: none !important;
                    }

                    ytd-watch-flexy {
                      --ytd-watch-flexy-sidebar-width: 0px !important;
                      --ytd-watch-flexy-max-player-width: 100vw !important;
                      --ytd-watch-flexy-space-below-player: 0px !important;
                      min-height: 100vh !important;
                      padding-top: 0 !important;
                    }

                    #columns,
                    #primary,
                    #primary-inner,
                    #full-bleed-container,
                    #player-full-bleed-container,
                    #player-container-outer,
                    #player-container-inner,
                    #container.ytd-player,
                    #movie_player,
                    .html5-video-player,
                    .html5-main-video,
                    video {
                      width: 100vw !important;
                      max-width: 100vw !important;
                      height: 100vh !important;
                      max-height: 100vh !important;
                      background: #000 !important;
                    }
                  `;

                  const player = document.getElementById('movie_player');
                  if (player && typeof player.setTheaterMode === 'function') {
                    player.setTheaterMode(true);
                  }
                })();
                """
                : """
                (() => {
                  document.documentElement.style.background = '#000';
                  document.body.style.background = '#000';
                })();
                """

            webView.evaluateJavaScript(script)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                webView.evaluateJavaScript(script)
            }
        }
    }
}
