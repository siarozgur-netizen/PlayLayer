import AppKit
import SwiftUI

@MainActor
final class ImagePanelWindowController: NSWindowController, NSWindowDelegate {
    private let opacity: Double
    private let initialFrame: CGRect
    let sourceURL: URL?
    private let closeObserver: () -> Void
    private var currentImage: NSImage
    private var isActive = false
    private var isClosingPanel = false

    init(opacity: Double, isInteractive: Bool, image: NSImage, sourceURL: URL? = nil, initialFrame: CGRect, closeObserver: @escaping () -> Void) {
        self.opacity = opacity
        self.initialFrame = initialFrame
        self.sourceURL = sourceURL
        self.closeObserver = closeObserver
        self.currentImage = image

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
        window.minSize = Self.minimumWindowSize(for: image.size)
        window.maxSize = Self.maximumWindowSize(for: image.size)
        window.contentAspectRatio = Self.aspectRatioSize(for: image.size)

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

    func updateImage(_ image: NSImage) {
        currentImage = image
        window?.minSize = Self.minimumWindowSize(for: image.size)
        window?.maxSize = Self.maximumWindowSize(for: image.size)
        window?.contentAspectRatio = Self.aspectRatioSize(for: image.size)
        applyRootView()
    }

    func copyImage() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([currentImage])
        print("[Lumi][ImagePanel] Copied image to pasteboard")
    }

    func saveImageAs() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = sourceURL?.deletingPathExtension().lastPathComponent ?? "Lumi Image"
        savePanel.title = "Save Image Panel"

        guard savePanel.runModal() == .OK, let destinationURL = savePanel.url else {
            return
        }

        guard
            let tiffData = currentImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            print("[Lumi][ImagePanel] Failed to encode image for save")
            return
        }

        do {
            try pngData.write(to: destinationURL, options: .atomic)
            print("[Lumi][ImagePanel] Saved image panel to \(destinationURL.path)")
        } catch {
            print("[Lumi][ImagePanel] Failed to save image panel: \(error.localizedDescription)")
        }
    }

    func setInteractive(_ enabled: Bool) {
        window?.ignoresMouseEvents = !enabled
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
        window?.maxSize = Self.maximumWindowSize(for: currentImage.size)
    }

    private func applyRootView() {
        let hostingView = NSHostingView(rootView: makeRootView(image: currentImage))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = PremiumPanelStyle.platformPanelSurfaceColor.cgColor
        window?.contentView = hostingView
    }

    private func makeRootView(image: NSImage) -> ImagePanelView {
        ImagePanelView(
            image: image,
            isActive: isActive,
            copyHandler: { [weak self] in self?.copyImage() },
            saveHandler: { [weak self] in self?.saveImageAs() },
            closeHandler: { [weak self] in self?.closePanel() }
        )
    }

    static func makePlaceholderImage() -> NSImage {
        let size = NSSize(width: 1600, height: 1000)
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).setFill()
        rect.fill()

        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.24, green: 0.72, blue: 1.0, alpha: 1.0),
            NSColor(calibratedRed: 0.14, green: 0.24, blue: 0.78, alpha: 1.0),
            NSColor(calibratedRed: 0.55, green: 0.18, blue: 0.84, alpha: 1.0)
        ])
        gradient?.draw(in: NSBezierPath(roundedRect: rect.insetBy(dx: 40, dy: 40), xRadius: 42, yRadius: 42), angle: -28)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 72, weight: .heavy),
            .foregroundColor: NSColor.white
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 34, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.82)
        ]

        let title = NSAttributedString(string: "Lumi Pinned Image", attributes: titleAttributes)
        let subtitle = NSAttributedString(string: "Screenshot Panel MVP placeholder", attributes: subtitleAttributes)

        title.draw(at: NSPoint(x: 110, y: 610))
        subtitle.draw(at: NSPoint(x: 114, y: 540))

        NSColor.white.withAlphaComponent(0.12).setFill()
        NSBezierPath(roundedRect: NSRect(x: 114, y: 210, width: 520, height: 92), xRadius: 24, yRadius: 24).fill()

        let badgeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 26, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        NSAttributedString(string: "Pinned • Draggable • Resizable", attributes: badgeAttributes)
            .draw(at: NSPoint(x: 146, y: 239))

        image.unlockFocus()
        return image
    }

    private static func minimumWindowSize(for imageSize: CGSize) -> NSSize {
        let width = max(imageSize.width, 1)
        let height = max(imageSize.height, 1)
        let aspectRatio = width / height

        if aspectRatio >= 1 {
            let minHeight: CGFloat = 110
            return NSSize(width: max(140, minHeight * aspectRatio), height: minHeight)
        } else {
            let minWidth: CGFloat = 110
            return NSSize(width: minWidth, height: max(140, minWidth / aspectRatio))
        }
    }

    private static func maximumWindowSize(for imageSize: CGSize) -> NSSize {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let aspect = max(imageSize.width, 1) / max(imageSize.height, 1)
        let maxWidth = min(screen.width * 0.72, 1320)
        let maxHeight = min(screen.height * 0.78, 980)
        let scale = min(maxWidth / max(imageSize.width, 1), maxHeight / max(imageSize.height, 1), 1.0)

        let width = min(max(imageSize.width * scale, minimumWindowSize(for: imageSize).width), maxWidth)
        let height = min(max(imageSize.height * scale, minimumWindowSize(for: imageSize).height), maxHeight)
        if aspect >= 1 {
            return NSSize(width: width, height: max(width / aspect, minimumWindowSize(for: imageSize).height))
        } else {
            return NSSize(width: max(height * aspect, minimumWindowSize(for: imageSize).width), height: height)
        }
    }

    private static func aspectRatioSize(for imageSize: CGSize) -> NSSize {
        let width = max(imageSize.width, 1)
        let height = max(imageSize.height, 1)
        return NSSize(width: width, height: height)
    }
}
