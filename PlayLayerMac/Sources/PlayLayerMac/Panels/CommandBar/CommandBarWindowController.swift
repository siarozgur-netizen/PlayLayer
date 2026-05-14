import AppKit
import SwiftUI

@MainActor
final class CommandBarWindowController: NSWindowController, NSWindowDelegate {
    private var actions: [CommandBarAction] = []
    private var isClosing = false
    private var suppressNextResignKeyClose = false

    init() {
        let frame = CommandBarWindowController.defaultFrame()
        let window = CommandBarWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        super.init(window: window)
        window.delegate = self
        applyRootView()
        window.cancelHandler = { [weak self] in
            self?.hideCommandBar()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showCommandBar(actions: [CommandBarAction], asHomeSurface: Bool = false) {
        self.actions = actions
        suppressNextResignKeyClose = asHomeSurface
        applyRootView()
        guard let window else { return }
        window.setFrame(Self.defaultFrame(), display: true, animate: false)
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        PanelMotion.animateCommandBarIn(window)
    }

    var isCommandBarVisible: Bool {
        window?.isVisible ?? false
    }

    var currentFrame: CGRect? {
        window?.frame
    }

    func hideCommandBar() {
        guard let window, !isClosing else { return }
        isClosing = true
        PanelMotion.animateCommandBarOut(window) { [weak self] in
            self?.window?.orderOut(nil)
            self?.isClosing = false
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        _ = notification
        if suppressNextResignKeyClose {
            suppressNextResignKeyClose = false
            return
        }
        hideCommandBar()
    }

    private func applyRootView() {
        let hostingView = NSHostingView(rootView: CommandBarView(actions: actions) { [weak self] action in
            self?.execute(action)
        })
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window?.contentView = hostingView
    }

    private func execute(_ action: CommandBarAction) {
        hideCommandBar()
        action.handler()
    }

    private static func defaultFrame() -> CGRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 462
        let height: CGFloat = 388
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.maxY - height - 72
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

@MainActor
private final class CommandBarWindow: NSWindow {
    var cancelHandler: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelHandler?()
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        _ = sender
        cancelHandler?()
    }
}
