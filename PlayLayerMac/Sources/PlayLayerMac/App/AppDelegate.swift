import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchGuardService = LaunchGuardService()
    private let configService = ConfigService()
    private let hotkeyService = HotkeyService()
    private lazy var trayService = TrayService(
        toggleOverlayHandler: { [weak self] in self?.toggleOverlay() },
        returnToHomeHandler: { [weak self] in self?.returnToHome() },
        showGuideHandler: { [weak self] in self?.showGuide() },
        enablePassModeHandler: { [weak self] in self?.setPassMode() },
        enableInteractModeHandler: { [weak self] in self?.setInteractMode() },
        quitHandler: { NSApplication.shared.terminate(nil) }
    )
    private var overlayWindowController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = notification

        guard launchGuardService.acquire() else {
            NSApplication.shared.terminate(nil)
            return
        }

        var config = configService.load()
        config.overlayFullscreenEnabled = false
        config.interactModeEnabled = true
        configService.save(config)
        overlayWindowController = OverlayWindowController(config: config, configService: configService)
        overlayWindowController?.showOverlay()
        trayService.install()
        hotkeyService.registerDefaultHotkeys(
            exitOverlayPlaybackModeHandler: { [weak self] in
                self?.overlayWindowController?.exitOverlayPlaybackMode()
            },
            returnToHomeHandler: { [weak self] in
                self?.overlayWindowController?.returnToHome()
            },
            toggleOverlayVisibilityHandler: { [weak self] in
                self?.overlayWindowController?.toggleOverlayVisibility()
            },
            showGuideHandler: { [weak self] in
                self?.overlayWindowController?.showGuide()
            },
            togglePlaybackHandler: { [weak self] in
                self?.overlayWindowController?.togglePlayback()
            },
            seekBackwardHandler: { [weak self] in
                self?.overlayWindowController?.seekBackward()
            },
            seekForwardHandler: { [weak self] in
                self?.overlayWindowController?.seekForward()
            }
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        _ = sender
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        _ = notification
        hotkeyService.unregisterAllHotkeys()
        overlayWindowController?.stopObservingSpaces()
    }

    private func showOverlay() {
        overlayWindowController?.showOverlay()
    }

    private func hideOverlay() {
        overlayWindowController?.hideOverlay()
    }

    private func toggleOverlay() {
        overlayWindowController?.toggleOverlayVisibility()
    }

    private func returnToHome() {
        overlayWindowController?.returnToHome()
    }

    private func showGuide() {
        overlayWindowController?.showGuide()
    }

    private func setPassMode() {
        overlayWindowController?.setInteractMode(false)
    }

    private func setInteractMode() {
        overlayWindowController?.setInteractMode(true)
    }
}
