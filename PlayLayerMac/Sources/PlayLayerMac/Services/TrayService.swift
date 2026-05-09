import AppKit

@MainActor
final class TrayService {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let toggleOverlayHandler: () -> Void
    private let returnToHomeHandler: () -> Void
    private let showGuideHandler: () -> Void
    private let enablePassModeHandler: () -> Void
    private let enableInteractModeHandler: () -> Void
    private let quitHandler: () -> Void

    init(
        toggleOverlayHandler: @escaping () -> Void,
        returnToHomeHandler: @escaping () -> Void,
        showGuideHandler: @escaping () -> Void,
        enablePassModeHandler: @escaping () -> Void,
        enableInteractModeHandler: @escaping () -> Void,
        quitHandler: @escaping () -> Void
    ) {
        self.toggleOverlayHandler = toggleOverlayHandler
        self.returnToHomeHandler = returnToHomeHandler
        self.showGuideHandler = showGuideHandler
        self.enablePassModeHandler = enablePassModeHandler
        self.enableInteractModeHandler = enableInteractModeHandler
        self.quitHandler = quitHandler
    }

    func install() {
        statusItem.button?.title = "▶︎"
        statusItem.button?.toolTip = "PlayLayer"
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "PlayLayer", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let subtitleItem = NSMenuItem(title: "Gaming video overlay", action: nil, keyEquivalent: "")
        subtitleItem.isEnabled = false
        menu.addItem(subtitleItem)

        menu.addItem(.separator())
        menu.addItem(makeItem("Toggle Overlay", action: #selector(onToggleOverlay), shortcut: "Ctrl Opt O"))
        menu.addItem(makeItem("Home", action: #selector(onHome), shortcut: "Ctrl Opt H"))
        menu.addItem(makeItem("Show Guide", action: #selector(onGuide), shortcut: "Ctrl Opt C"))
        menu.addItem(.separator())
        menu.addItem(makeItem("Pass Mode", action: #selector(onPassMode), shortcut: "game input"))
        menu.addItem(makeItem("Interact Mode", action: #selector(onInteractMode), shortcut: "overlay input"))
        menu.addItem(makeItem("Exit Theater", action: #selector(onHome), shortcut: "Ctrl Opt T / H"))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit PlayLayer", action: #selector(onQuit), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        return menu
    }

    private func makeItem(_ title: String, action: Selector, shortcut: String) -> NSMenuItem {
        let item = NSMenuItem(title: "\(title)    \(shortcut)", action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc
    private func onToggleOverlay() {
        toggleOverlayHandler()
    }

    @objc
    private func onHome() {
        returnToHomeHandler()
    }

    @objc
    private func onGuide() {
        showGuideHandler()
    }

    @objc
    private func onPassMode() {
        enablePassModeHandler()
    }

    @objc
    private func onInteractMode() {
        enableInteractModeHandler()
    }

    @objc
    private func onQuit() {
        quitHandler()
    }
}
