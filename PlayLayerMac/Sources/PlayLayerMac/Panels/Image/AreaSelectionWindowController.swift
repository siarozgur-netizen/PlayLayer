import AppKit

@MainActor
final class AreaSelectionWindowController: NSWindowController, NSWindowDelegate {
    private let screen: NSScreen
    private let completion: (CGRect?) -> Void
    private var didFinishSelection = false

    init(screen: NSScreen, completion: @escaping (CGRect?) -> Void) {
        self.screen = screen
        self.completion = completion

        let window = AreaSelectionWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true

        super.init(window: window)

        let selectionView = AreaSelectionView { [weak self] localRect in
            self?.finishSelection(with: localRect)
        } cancelHandler: { [weak self] in
            self?.cancelSelection()
        }

        window.contentView = selectionView
        window.delegate = self
        window.cancelHandler = { [weak self] in
            self?.cancelSelection()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSelectionOverlay() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func windowWillClose(_ notification: Notification) {
        _ = notification
        guard !didFinishSelection else { return }
        didFinishSelection = true
        completion(nil)
    }

    private func finishSelection(with localRect: CGRect?) {
        guard !didFinishSelection else { return }
        didFinishSelection = true

        let screenRect = localRect.map {
            CGRect(
                x: screen.frame.minX + $0.minX,
                y: screen.frame.minY + $0.minY,
                width: $0.width,
                height: $0.height
            )
        }

        window?.close()
        completion(screenRect)
    }

    private func cancelSelection() {
        guard !didFinishSelection else { return }
        didFinishSelection = true
        window?.close()
        completion(nil)
    }
}

@MainActor
private final class AreaSelectionWindow: NSWindow {
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

@MainActor
private final class AreaSelectionView: NSView {
    private let selectionHandler: (CGRect?) -> Void
    private let cancelHandler: () -> Void
    private var dragStartPoint: NSPoint?
    private var currentPoint: NSPoint?

    init(selectionHandler: @escaping (CGRect?) -> Void, cancelHandler: @escaping () -> Void) {
        self.selectionHandler = selectionHandler
        self.cancelHandler = cancelHandler
        super.init(frame: .zero)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var isOpaque: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelHandler()
            return
        }

        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStartPoint = point
        currentPoint = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        let selectionRect = currentSelectionRect()
        dragStartPoint = nil
        currentPoint = nil
        needsDisplay = true

        guard let selectionRect, selectionRect.width >= 12, selectionRect.height >= 12 else {
            selectionHandler(nil)
            return
        }

        selectionHandler(selectionRect)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()

        let overlayPath = NSBezierPath(rect: bounds)
        if let selectionRect = currentSelectionRect() {
            overlayPath.append(NSBezierPath(roundedRect: selectionRect, xRadius: 10, yRadius: 10))
            overlayPath.windingRule = .evenOdd
        }

        NSColor.black.withAlphaComponent(0.22).setFill()
        overlayPath.fill()

        if let selectionRect = currentSelectionRect() {
            NSColor.white.withAlphaComponent(0.92).setStroke()
            let strokePath = NSBezierPath(roundedRect: selectionRect, xRadius: 10, yRadius: 10)
            strokePath.lineWidth = 2
            strokePath.stroke()
        }
    }

    private func currentSelectionRect() -> CGRect? {
        guard let dragStartPoint, let currentPoint else { return nil }
        return CGRect(
            x: min(dragStartPoint.x, currentPoint.x),
            y: min(dragStartPoint.y, currentPoint.y),
            width: abs(currentPoint.x - dragStartPoint.x),
            height: abs(currentPoint.y - dragStartPoint.y)
        )
    }
}
