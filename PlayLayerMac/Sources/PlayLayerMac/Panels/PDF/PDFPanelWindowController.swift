import AppKit
import PDFKit
import SwiftUI

@MainActor
final class PDFPanelWindowController: NSWindowController, NSWindowDelegate {
    private let opacity: Double
    private let initialFrame: CGRect
    let sourceURL: URL?
    private let closeObserver: () -> Void
    private var currentDocument: PDFDocument
    private var isActive = false
    private var isClosingPanel = false

    init(opacity: Double, isInteractive: Bool, document: PDFDocument, sourceURL: URL? = nil, initialFrame: CGRect, closeObserver: @escaping () -> Void) {
        self.opacity = opacity
        self.initialFrame = initialFrame
        self.sourceURL = sourceURL
        self.closeObserver = closeObserver
        self.currentDocument = document

        let window = PanelWindow(
            contentRect: initialFrame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = PremiumPanelStyle.platformPanelSurfaceColor
        window.isOpaque = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.hasShadow = true
        window.ignoresMouseEvents = !isInteractive
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 380, height: 240)
        window.maxSize = Self.maximumWindowSize()

        super.init(window: window)

        applyRootView()
        window.delegate = self
        window.setFrame(initialFrame, display: true, animate: false)
        window.alphaValue = opacity
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPanel() {
        guard let window else { return }
        window.alphaValue = opacity
        window.makeKeyAndOrderFront(nil)
        PanelMotion.animateIn(window)
    }

    var isPanelVisible: Bool {
        window?.isVisible ?? false
    }

    var currentFrame: CGRect? {
        window?.frame
    }

    func setInteractive(_ enabled: Bool) {
        window?.ignoresMouseEvents = !enabled
    }

    func openInPreview() {
        guard let sourceURL else { return }
        NSWorkspace.shared.open(sourceURL)
        print("[Lumi][PDFPanel] Opened PDF in Preview: \(sourceURL.path)")
    }

    func copyFilePath() {
        guard let sourceURL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sourceURL.path, forType: .string)
        print("[Lumi][PDFPanel] Copied PDF path: \(sourceURL.path)")
    }

    func hidePanel() {
        guard let window, window.isVisible, !isClosingPanel else { return }
        PanelMotion.animateOut(window) { [weak self] in
            self?.window?.orderOut(nil)
        }
    }

    func closePanel() {
        guard let window, !isClosingPanel else { return }
        isClosingPanel = true
        PanelMotion.animateOut(window) { [weak self] in
            self?.window?.close()
        }
    }

    func windowWillClose(_ notification: Notification) {
        _ = notification
        isClosingPanel = false
        closeObserver()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        _ = notification
        isActive = true
        applyRootView()
    }

    func windowDidResignKey(_ notification: Notification) {
        _ = notification
        isActive = false
        applyRootView()
    }

    func windowDidMove(_ notification: Notification) {
        _ = notification
    }

    func windowDidChangeScreen(_ notification: Notification) {
        _ = notification
        window?.maxSize = Self.maximumWindowSize()
    }

    private func applyRootView() {
        let hostingView = NSHostingView(rootView: makeRootView(document: currentDocument))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = PremiumPanelStyle.platformPanelSurfaceColor.cgColor
        window?.contentView = hostingView
    }

    private func makeRootView(document: PDFDocument) -> PDFPanelView {
        PDFPanelView(
            document: document,
            isActive: isActive,
            openInPreviewHandler: { [weak self] in self?.openInPreview() },
            copyPathHandler: { [weak self] in self?.copyFilePath() },
            closeHandler: { [weak self] in self?.closePanel() }
        )
    }

    private static func maximumWindowSize() -> NSSize {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        return NSSize(
            width: min(screen.width - 36, screen.width * 0.82),
            height: min(screen.height - 36, screen.height * 0.88)
        )
    }
}
