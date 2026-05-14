import AppKit
import SwiftUI
import Combine

@MainActor
final class PanelWindowController: NSWindowController, NSWindowDelegate {
    private let layoutService = PanelLayoutService()
    private let configService: ConfigService
    private var config: AppConfig
    private let runtimeState: PanelRuntimeState
    private let shortcutsPanelWindowController = ShortcutsPanelWindowController()
    private var cancellables = Set<AnyCancellable>()
    private var lastVideoMode = false
    private var activeSpaceObserver: NSObjectProtocol?
    private var pendingSpaceRecoveryWorkItem: DispatchWorkItem?

    init(config: AppConfig, configService: ConfigService) {
        self.config = config
        self.configService = configService
        self.runtimeState = PanelRuntimeState(
            isOverlayFullscreen: false
        )
        self.runtimeState.webPanelBridge.initialURLString = config.panelHomeURL

        let frame = Self.savedBrowseFrame(from: config) ?? layoutService.browseFrame()
        let window = PanelWindow(
            contentRect: frame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hasShadow = true
        window.ignoresMouseEvents = !config.interactModeEnabled
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.minSize = NSSize(width: 420, height: 260)
        window.maxSize = Self.maximumWebPanelSize()

        super.init(window: window)
        window.delegate = self
        let rootView = WebPanelView(
            runtimeState: runtimeState,
            onReload: { [weak self] in self?.reloadWebContent() },
            onOpenInBrowser: { [weak self] in self?.openCurrentURLInBrowser() },
            onCopyURL: { [weak self] in self?.copyCurrentURL() },
            onClose: { [weak self] in self?.hideOverlay() }
        )
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = hostingView
        bindRuntimeState()
        installActiveSpaceObserver()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func stopObservingSpaces() {
        pendingSpaceRecoveryWorkItem?.cancel()
        pendingSpaceRecoveryWorkItem = nil

        if let activeSpaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activeSpaceObserver)
            self.activeSpaceObserver = nil
        }
    }

    func showOverlay(showFeedback: Bool = true) {
        presentOverlay(activateApp: true)
        if showFeedback {
            runtimeState.showActionFeedback(icon: "eye.fill", title: "Shown")
        }
    }

    var isOverlayVisible: Bool {
        window?.isVisible ?? false
    }

    var currentFrame: CGRect? {
        window?.frame
    }

    var currentURLString: String {
        runtimeState.webPanelBridge.currentURLString
    }

    func hideOverlay() {
        runtimeState.showActionFeedback(icon: "eye.slash.fill", title: "Hidden")
        guard let window else { return }
        PanelMotion.animateOut(window) { [weak self] in
            self?.window?.orderOut(nil)
        }
    }

    func toggleOverlayVisibility() {
        guard let window else { return }

        if window.isVisible {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    private func presentOverlay(activateApp: Bool) {
        guard let window else { return }
        let shouldAnimate = !window.isVisible
        applyLayoutForCurrentMode()
        configureWindowForOverlayBehavior(window)
        window.alphaValue = config.opacity
        updateWindowMode()

        if activateApp {
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderFrontRegardless()
        }

        if shouldAnimate {
            PanelMotion.animateIn(window)
        }
    }

    func setInteractMode(_ enabled: Bool) {
        config.interactModeEnabled = enabled
        configService.save(config)
        updateWindowMode()
    }

    func toggleInteractMode() {
        setInteractMode(!config.interactModeEnabled)
    }

    func showGuide() {
        shortcutsPanelWindowController.showPanel()
    }

    func showActionFeedback(icon: String, title: String) {
        runtimeState.showActionFeedback(icon: icon, title: title)
    }

    func togglePlayback() {
        runtimeState.webPanelBridge.togglePlayback()
        runtimeState.showActionFeedback(icon: "playpause.fill", title: "Play / Pause")
    }

    func seekBackward() {
        runtimeState.webPanelBridge.seek(by: -10)
        runtimeState.showActionFeedback(icon: "gobackward.10", title: "-10s")
    }

    func seekForward() {
        runtimeState.webPanelBridge.seek(by: 10)
        runtimeState.showActionFeedback(icon: "goforward.10", title: "+10s")
    }

    private func reloadWebContent() {
        runtimeState.webPanelBridge.reload()
        runtimeState.showActionFeedback(icon: "arrow.clockwise", title: "Reloaded")
    }

    private func openCurrentURLInBrowser() {
        guard let url = URL(string: currentURLString) else { return }
        NSWorkspace.shared.open(url)
        runtimeState.showActionFeedback(icon: "safari.fill", title: "Opened in Browser")
    }

    private func copyCurrentURL() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentURLString, forType: .string)
        runtimeState.showActionFeedback(icon: "link", title: "Copied URL")
    }

    func toggleTheaterMode() {
        guard runtimeState.isVideoMode || runtimeState.isPlaybackLocked else {
            runtimeState.showActionFeedback(icon: "rectangle.on.rectangle.slash.fill", title: "Theater Unavailable")
            return
        }

        runtimeState.isPlaybackLocked.toggle()
        runtimeState.isOverlayFullscreen = false
        applyLayoutForCurrentMode()
        runtimeState.showActionFeedback(
            icon: runtimeState.isPlaybackLocked ? "rectangle.expand.vertical" : "rectangle.compress.vertical",
            title: runtimeState.isPlaybackLocked ? "Theater" : "Exit Theater"
        )
    }

    func returnToHome() {
        runtimeState.isPlaybackLocked = false
        runtimeState.isOverlayFullscreen = false
        runtimeState.webPanelBridge.navigateHome()
        applyLayoutForCurrentMode()
        runtimeState.showActionFeedback(icon: "house.fill", title: "Home")
    }

    private func updateWindowMode() {
        window?.ignoresMouseEvents = !config.interactModeEnabled

        if config.interactModeEnabled, let window, window.isVisible {
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func bindRuntimeState() {
        runtimeState.$isVideoMode
            .removeDuplicates()
            .sink { [weak self] isVideoMode in
                self?.handleVideoModeTransition(isVideoMode)
            }
            .store(in: &cancellables)

        runtimeState.$isOverlayFullscreen
            .removeDuplicates()
            .sink { [weak self] isFullscreen in
                guard let self else { return }
                self.config.overlayFullscreenEnabled = isFullscreen
                self.configService.save(self.config)
                self.applyLayoutForCurrentMode()
            }
            .store(in: &cancellables)
    }

    private func handleVideoModeTransition(_ isVideoMode: Bool) {
        defer {
            lastVideoMode = isVideoMode
        }

        if isVideoMode && !lastVideoMode {
            applyLayoutForCurrentMode()
            return
        }

        if !isVideoMode && lastVideoMode {
            if runtimeState.isPlaybackLocked {
                return
            }

            runtimeState.isOverlayFullscreen = false
            applyLayoutForCurrentMode()
            return
        }

        applyLayoutForCurrentMode()
    }

    private func applyLayoutForCurrentMode() {
        guard let window else { return }

        if runtimeState.isOverlayFullscreen {
            layoutService.applyFullscreenOverlayFrame(to: window)
        } else if runtimeState.isPlaybackLocked {
            layoutService.applyTheaterFrame(to: window)
        } else {
            let targetFrame = Self.savedBrowseFrame(from: config) ?? layoutService.browseFrame()
            guard !window.frame.integral.equalTo(targetFrame.integral) else { return }
            window.setFrame(targetFrame, display: true, animate: false)
        }
    }

    private func installActiveSpaceObserver() {
        activeSpaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.scheduleActiveSpaceRecovery()
            }
        }
    }

    private func scheduleActiveSpaceRecovery() {
        pendingSpaceRecoveryWorkItem?.cancel()
        print("[PlayLayer][Spaces] Active Space changed, scheduling overlay recovery")

        let workItem = DispatchWorkItem { [weak self] in
            self?.recoverOverlayAfterActiveSpaceChange()
        }

        pendingSpaceRecoveryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }

    private func recoverOverlayAfterActiveSpaceChange() {
        guard let window else {
            print("[PlayLayer][Spaces] Recovery skipped: no window")
            return
        }

        guard window.isVisible else {
            print("[PlayLayer][Spaces] Recovery skipped: overlay hidden")
            return
        }

        print("[PlayLayer][Spaces] Reapplying overlay state after Space change")
        configureWindowForOverlayBehavior(window)
        applyLayoutForCurrentMode()
        window.alphaValue = config.opacity
        window.orderFrontRegardless()

        if !window.isOnActiveSpace {
            print("[PlayLayer][Spaces] Overlay still not on active Space, forcing refresh")
            window.orderOut(nil)
            configureWindowForOverlayBehavior(window)
            applyLayoutForCurrentMode()
            window.alphaValue = config.opacity
            window.orderFrontRegardless()
        }
    }

    private func configureWindowForOverlayBehavior(_ window: NSWindow) {
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = !config.interactModeEnabled
    }

    func windowDidMove(_ notification: Notification) {
        _ = notification
        persistCurrentBrowseFrameIfNeeded()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        _ = notification
        persistCurrentBrowseFrameIfNeeded()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        _ = notification
        window?.maxSize = Self.maximumWebPanelSize()
    }

    private func persistCurrentBrowseFrameIfNeeded() {
        guard shouldPersistCurrentBrowseFrame, let window else { return }

        config.panelFrameX = window.frame.origin.x
        config.panelFrameY = window.frame.origin.y
        config.panelFrameWidth = window.frame.width
        config.panelFrameHeight = window.frame.height
        configService.save(config)
    }

    private var shouldPersistCurrentBrowseFrame: Bool {
        !runtimeState.isOverlayFullscreen && !runtimeState.isPlaybackLocked
    }

    private static func savedBrowseFrame(from config: AppConfig) -> CGRect? {
        guard
            let x = config.panelFrameX,
            let y = config.panelFrameY,
            let width = config.panelFrameWidth,
            let height = config.panelFrameHeight,
            width >= 360,
            height >= 220
        else {
            return nil
        }

        let savedFrame = CGRect(x: x, y: y, width: width, height: height)
        let visibleFrame = NSScreen.main?.visibleFrame ?? savedFrame
        let constrainedWidth = min(max(savedFrame.width, 360), visibleFrame.width)
        let constrainedHeight = min(max(savedFrame.height, 220), visibleFrame.height)
        let constrainedX = min(max(savedFrame.minX, visibleFrame.minX), visibleFrame.maxX - constrainedWidth)
        let constrainedY = min(max(savedFrame.minY, visibleFrame.minY), visibleFrame.maxY - constrainedHeight)

        return CGRect(
            x: constrainedX,
            y: constrainedY,
            width: constrainedWidth,
            height: constrainedHeight
        )
    }

    private static func maximumWebPanelSize() -> NSSize {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        return NSSize(
            width: min(screen.width - 32, screen.width * 0.84),
            height: min(screen.height - 32, screen.height * 0.84)
        )
    }
}
