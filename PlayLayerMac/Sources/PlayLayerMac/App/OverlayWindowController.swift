import AppKit
import SwiftUI
import Combine

@MainActor
final class OverlayWindowController: NSWindowController {
    private let layoutService = OverlayLayoutService()
    private let configService: ConfigService
    private var config: AppConfig
    private let runtimeState: OverlayRuntimeState
    private var cancellables = Set<AnyCancellable>()
    private var lastVideoMode = false
    private var activeSpaceObserver: NSObjectProtocol?
    private var pendingSpaceRecoveryWorkItem: DispatchWorkItem?

    init(config: AppConfig, configService: ConfigService) {
        self.config = config
        self.configService = configService
        self.runtimeState = OverlayRuntimeState(
            indicatorText: "",
            isOverlayFullscreen: false
        )

        let frame = layoutService.browseFrame()
        let window = OverlayWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.isOpaque = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hasShadow = true
        window.ignoresMouseEvents = !config.interactModeEnabled
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true

        let rootView = OverlayRootView(runtimeState: runtimeState)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.black.cgColor
        window.contentView = hostingView

        super.init(window: window)
        updateIndicator()
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

    func showOverlay() {
        presentOverlay(activateApp: true)
        runtimeState.showActionFeedback(icon: "eye.fill", title: "Shown")
    }

    func hideOverlay() {
        runtimeState.showActionFeedback(icon: "eye.slash.fill", title: "Hidden")
        window?.orderOut(nil)
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
        applyLayoutForCurrentMode()
        configureWindowForOverlayBehavior(window)
        window.alphaValue = config.opacity
        updateWindowMode()

        if activateApp {
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        } else {
            window.orderFrontRegardless()
        }
    }

    func setInteractMode(_ enabled: Bool) {
        config.interactModeEnabled = enabled
        configService.save(config)
        updateWindowMode()
        updateIndicator()
    }

    func toggleInteractMode() {
        setInteractMode(!config.interactModeEnabled)
    }

    func showGuide() {
        runtimeState.requestGuide()
        runtimeState.showActionFeedback(icon: "keyboard.fill", title: "Guide")
    }

    func togglePlayback() {
        runtimeState.webViewBridge.togglePlayback()
        runtimeState.showActionFeedback(icon: "playpause.fill", title: "Play / Pause")
    }

    func seekBackward() {
        runtimeState.webViewBridge.seek(by: -10)
        runtimeState.showActionFeedback(icon: "gobackward.10", title: "-10s")
    }

    func seekForward() {
        runtimeState.webViewBridge.seek(by: 10)
        runtimeState.showActionFeedback(icon: "goforward.10", title: "+10s")
    }

    func exitOverlayPlaybackMode() {
        runtimeState.isPlaybackLocked = false
        runtimeState.isOverlayFullscreen = false
        setInteractMode(true)
        applyLayoutForCurrentMode()
        runtimeState.showActionFeedback(icon: "rectangle.compress.vertical", title: "Exit Theater")
    }

    func returnToHome() {
        runtimeState.isPlaybackLocked = false
        runtimeState.isOverlayFullscreen = false
        runtimeState.webViewBridge.navigateHome()
        setInteractMode(true)
        applyLayoutForCurrentMode()
        runtimeState.showActionFeedback(icon: "house.fill", title: "Home")
    }

    private func updateWindowMode() {
        window?.ignoresMouseEvents = !config.interactModeEnabled

        if config.interactModeEnabled, let window, window.isVisible {
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func updateIndicator() {
        let percent = Int((config.opacity * 100).rounded())
        runtimeState.indicatorText = "\(config.interactModeEnabled ? "INTERACT" : "PASS") \(percent)%"
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
            runtimeState.isPlaybackLocked = true
            runtimeState.isOverlayFullscreen = false
            setInteractMode(false)
            applyLayoutForCurrentMode()
            runtimeState.requestTheaterTransition()
            runtimeState.showActionFeedback(icon: "play.rectangle.fill", title: "Theater · PASS")
            return
        }

        if !isVideoMode && lastVideoMode {
            if runtimeState.isPlaybackLocked {
                return
            }

            runtimeState.isOverlayFullscreen = false
            setInteractMode(true)
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
        } else if runtimeState.isVideoMode {
            layoutService.applyTheaterFrame(to: window)
        } else {
            layoutService.applyBrowseFrame(to: window)
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
}
