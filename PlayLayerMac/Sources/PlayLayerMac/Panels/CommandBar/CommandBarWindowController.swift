import AppKit
import SwiftUI

@MainActor
final class CommandBarWindowController: NSWindowController, NSWindowDelegate {
    private var actions: [CommandBarAction] = []
    private var commandExecutor: ((String) -> Bool)?
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
        window.isMovableByWindowBackground = true

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

    func showCommandBar(
        actions: [CommandBarAction],
        commandExecutor: ((String) -> Bool)? = nil,
        asHomeSurface: Bool = false
    ) {
        self.actions = actions
        self.commandExecutor = commandExecutor
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
        let hostingView = CommandBarHostingView(
            rootView: CommandBarView(
                actions: actions,
                executeAction: { [weak self] action in
                    self?.execute(action)
                },
                executeCommand: { [weak self] command in
                    self?.executeCommand(command) ?? false
                }
            )
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window?.contentView = hostingView
    }

    private func execute(_ action: CommandBarAction) {
        hideCommandBar()
        action.handler()
    }

    private func executeCommand(_ command: String) -> Bool {
        let didExecute = commandExecutor?(command) ?? false
        if didExecute {
            hideCommandBar()
        }
        return didExecute
    }

    private static func defaultFrame() -> CGRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = min(820, visibleFrame.width - 56)
        let height: CGFloat = 228
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.minY + 34
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

@MainActor
private final class CommandBarHostingView: NSHostingView<CommandBarView> {
    override var mouseDownCanMoveWindow: Bool { true }
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
