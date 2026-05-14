import SwiftUI
import WebKit

struct WebPanelView: View {
    @ObservedObject var runtimeState: PanelRuntimeState
    let onReload: () -> Void
    let onOpenInBrowser: () -> Void
    let onCopyURL: () -> Void
    let onClose: () -> Void
    @State private var showsStartupHint = true
    @State private var isPointerInsidePanel = false
    @State private var hideStartupHintWorkItem: DispatchWorkItem?
    @State private var visibleFeedback: ActionFeedback?
    @State private var hideFeedbackWorkItem: DispatchWorkItem?
    @State private var showsTheaterTransition = false
    @State private var hideTheaterTransitionWorkItem: DispatchWorkItem?
    @State private var isDragging = false
    @State private var isPointerOverControlDock = false

    init(
        runtimeState: PanelRuntimeState,
        onReload: @escaping () -> Void = {},
        onOpenInBrowser: @escaping () -> Void = {},
        onCopyURL: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.runtimeState = runtimeState
        self.onReload = onReload
        self.onOpenInBrowser = onOpenInBrowser
        self.onCopyURL = onCopyURL
        self.onClose = onClose
    }

    private var showsControlDock: Bool {
        isPointerInsidePanel || isPointerOverControlDock
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                WebPanelContainerView(
                    bridge: runtimeState.webPanelBridge,
                    isTheaterMode: runtimeState.isPlaybackLocked
                )
                    .integratedPanelContent(fillColor: PremiumPanelStyle.contentBedColor)
                    .padding(PremiumPanelStyle.contentInset + 1)

                PanelHoverTrackerView(isPointerInsidePanel: $isPointerInsidePanel)
                    .allowsHitTesting(false)

                if showsStartupHint {
                    StartupHintPill()
                        .padding(.top, 14)
                        .padding(.leading, 14)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            .background(Color.clear)
            .premiumPanelChrome(isActive: true, isHovered: isPointerInsidePanel, isDragging: isDragging, usesFilledSurface: true)

            WebPanelControlDock(
                isDragging: $isDragging,
                onReload: onReload,
                onOpenInBrowser: onOpenInBrowser,
                onCopyURL: onCopyURL,
                onClose: onClose
            )
            .onHover { isPointerOverControlDock = $0 }
            .opacity(showsControlDock ? 1 : 0)
            .scaleEffect(showsControlDock ? 1 : 0.96, anchor: .top)
            .allowsHitTesting(showsControlDock)
            .offset(y: showsControlDock ? -12 : -54)
        }
        .animation(.easeOut(duration: 0.16), value: showsStartupHint)
        .animation(.easeOut(duration: 0.14), value: visibleFeedback)
        .animation(.easeOut(duration: 0.18), value: showsTheaterTransition)
        .animation(.easeOut(duration: 0.12), value: isPointerInsidePanel)
        .animation(.easeOut(duration: 0.14), value: showsControlDock)
        .onAppear {
            showStartupHintTemporarily()
        }
        .onChange(of: runtimeState.actionFeedback) { feedback in
            showFeedbackTemporarily(feedback)
        }
        .onChange(of: runtimeState.theaterTransitionID) { _ in
            showTheaterTransition()
        }
        .onDisappear {
            hideStartupHintWorkItem?.cancel()
            hideStartupHintWorkItem = nil
            hideFeedbackWorkItem?.cancel()
            hideFeedbackWorkItem = nil
            hideTheaterTransitionWorkItem?.cancel()
            hideTheaterTransitionWorkItem = nil
        }
    }

    private func showStartupHintTemporarily() {
        hideStartupHintWorkItem?.cancel()
        showsStartupHint = true

        let workItem = DispatchWorkItem {
            showsStartupHint = false
        }

        hideStartupHintWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: workItem)
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

private struct WebPanelControlDock: View {
    @Binding var isDragging: Bool
    let onReload: () -> Void
    let onOpenInBrowser: () -> Void
    let onCopyURL: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 2) {
            ZStack {
                PanelDragSurfaceView(isDragging: $isDragging)
                    .frame(width: 152, height: 34)

                FloatingPanelChromeContainer {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                    Text("Move Window")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                }
                .allowsHitTesting(false)
            }

            FloatingPanelChromeContainer {
                FloatingPanelIconButton(icon: "arrow.clockwise", action: onReload)
                FloatingPanelIconButton(icon: "safari", action: onOpenInBrowser)
                FloatingPanelIconButton(icon: "link", action: onCopyURL)
                FloatingTrafficLightCloseButton(action: onClose)
            }
        }
        .padding(.top, 6)
    }
}

private struct PanelHoverTrackerView: NSViewRepresentable {
    @Binding var isPointerInsidePanel: Bool

    func makeNSView(context: Context) -> PanelHoverTrackingNSView {
        let view = PanelHoverTrackingNSView()
        view.hoverChanged = { isInside in
            if isPointerInsidePanel != isInside {
                isPointerInsidePanel = isInside
            }
        }
        return view
    }

    func updateNSView(_ nsView: PanelHoverTrackingNSView, context: Context) {
        _ = context
        nsView.hoverChanged = { isInside in
            if isPointerInsidePanel != isInside {
                isPointerInsidePanel = isInside
            }
        }
        nsView.updateTrackingAreas()
    }
}

@MainActor
private final class PanelHoverTrackingNSView: NSView {
    var hoverChanged: ((Bool) -> Void)?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        _ = point
        return nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        _ = event
        hoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        _ = event
        hoverChanged?(false)
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

private struct StartupHintPill: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "command")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.45, green: 0.78, blue: 1.0))

            Text("Press Ctrl + Option + L or Space to open Lumi")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.black.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 16, x: 0, y: 8)
    }
}

struct WebPanelContainerView: NSViewRepresentable {
    let bridge: WebPanelBridge
    let isTheaterMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(bridge: bridge, isTheaterMode: isTheaterMode)
    }

    func makeNSView(context: Context) -> WebPanelContainerNSView {
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
        webView.layer?.backgroundColor = PremiumPanelStyle.platformContentBedColor.cgColor
        webView.setValue(true, forKey: "drawsBackground")
        if #available(macOS 15.0, *) {
            webView.underPageBackgroundColor = PremiumPanelStyle.platformContentBedColor
        }
        bridge.attach(webView)
        webView.load(URLRequest(url: URL(string: bridge.initialURLString)!))
        return WebPanelContainerNSView(webView: webView)
    }

    func updateNSView(_ nsView: WebPanelContainerNSView, context: Context) {
        _ = nsView
        context.coordinator.setTheaterMode(isTheaterMode)
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
        private let bridge: WebPanelBridge
        private var isTheaterMode: Bool

        init(bridge: WebPanelBridge, isTheaterMode: Bool) {
            self.bridge = bridge
            self.isTheaterMode = isTheaterMode
        }

        func setTheaterMode(_ isTheaterMode: Bool) {
            guard self.isTheaterMode != isTheaterMode else { return }
            self.isTheaterMode = isTheaterMode
            if let webView = bridge.webView {
                applyProviderChromeSuppression(to: webView)
            }
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
            applyProviderChromeSuppression(to: webView)
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

            let isVideoMode = bridge.isPanelVideoURL(url)
            bridge.onNavigationStateChanged?(isVideoMode, body)

            if let webView = bridge.webView {
                applyProviderChromeSuppression(to: webView)
            }
        }

        private func applyProviderChromeSuppression(to webView: WKWebView) {
            let isVideoPage = webView.url.map { bridge.isPanelVideoURL($0) } ?? false
            let script: String

            if isVideoPage && isTheaterMode {
                script = """
                (() => {
                  document.documentElement.style.background = '#000';
                  document.body.style.background = '#000';
                  document.body.style.margin = '0';

                  document.getElementById('playlayer-watch-style')?.remove();
                  document.getElementById('playlayer-browse-style')?.remove();

                  const styleId = 'playlayer-theater-style';
                  let style = document.getElementById(styleId);
                  if (!style) {
                    style = document.createElement('style');
                    style.id = styleId;
                    document.head.appendChild(style);
                  }

                  style.textContent = `
                    html, body, ytd-app, #content, #page-manager, ytd-watch-flexy, #columns, #primary, #primary-inner {
                      margin: 0 !important;
                      padding: 0 !important;
                      background: #000 !important;
                    }

                    #masthead,
                    #masthead-container,
                    ytd-masthead,
                    #secondary,
                    #secondary-inner,
                    #below,
                    #related,
                    #comments,
                    #chat-container,
                    #header,
                    #endscreen,
                    #playlist,
                    ytd-watch-metadata,
                    ytd-merch-shelf-renderer,
                    tp-yt-app-drawer,
                    .ytp-chrome-top,
                    .ytp-youtube-button,
                    .ytp-fullscreen-button,
                    .ytp-size-button,
                    .ytp-gradient-top {
                      display: none !important;
                      opacity: 0 !important;
                      visibility: hidden !important;
                      pointer-events: none !important;
                    }

                    ytd-watch-flexy {
                      --ytd-watch-flexy-sidebar-width: 0px !important;
                      --ytd-watch-flexy-max-player-width: 100vw !important;
                      --ytd-watch-flexy-space-below-player: 0px !important;
                      padding-top: 0 !important;
                    }

                    #full-bleed-container,
                    #player-full-bleed-container,
                    #player-container-outer,
                    #player-container-inner,
                    #container.ytd-player,
                    #movie_player,
                    .html5-video-player,
                    .html5-video-container,
                    .html5-main-video,
                    video {
                      width: 100% !important;
                      max-width: 100% !important;
                      height: 100% !important;
                      max-height: 100% !important;
                      background: #000 !important;
                    }

                    #player-full-bleed-container,
                    #player-container-outer,
                    #player-container-inner,
                    #movie_player,
                    .html5-video-player,
                    .html5-video-container {
                      min-height: 100vh !important;
                    }
                  `;
                })();
                """
            } else {
                script = """
                (() => {
                  document.getElementById('playlayer-theater-style')?.remove();
                  document.getElementById('playlayer-browse-style')?.remove();
                  document.getElementById('playlayer-watch-style')?.remove();
                  document.documentElement.style.background = '';
                  document.body.style.background = '';
                  document.body.style.margin = '';
                })();
                """
            }

            webView.evaluateJavaScript(script)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                webView.evaluateJavaScript(script)
            }
        }
    }
}

@MainActor
final class WebPanelContainerNSView: NSView {
    private let webView: WKWebView

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = PremiumPanelStyle.platformContentBedColor.cgColor
        layer?.cornerCurve = .continuous
        addSubview(webView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        webView.frame = bounds
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        _ = event
        return true
    }
}
