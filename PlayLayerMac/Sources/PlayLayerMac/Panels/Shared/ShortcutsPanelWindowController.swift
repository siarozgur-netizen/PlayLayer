import AppKit
import SwiftUI

@MainActor
final class ShortcutsPanelWindowController: NSWindowController, NSWindowDelegate {
    private let layoutService = PanelLayoutService()
    private var isActive = false
    private var hasPositionedInitialFrame = false
    private var isClosing = false
    private var hostingView: ShortcutsPanelHostingView?

    init() {
        let initialSize = PanelLayoutService().guidePanelSpawnSize()
        let window = ShortcutsPanelWindow(
            contentRect: CGRect(origin: .zero, size: initialSize),
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
        window.ignoresMouseEvents = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.minSize = initialSize
        window.maxSize = initialSize

        super.init(window: window)
        window.delegate = self
        window.cancelHandler = { [weak self] in
            self?.hidePanel()
        }
        applyRootView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isPanelVisible: Bool {
        window?.isVisible ?? false
    }

    func showPanel(avoiding existingFrames: [CGRect] = [], focusArea: CGRect? = nil) {
        _ = focusArea
        guard let window else { return }

        if !hasPositionedInitialFrame || !window.isVisible {
            let frame = layoutService.nextAuxiliaryPanelFrame(
                size: layoutService.guidePanelSpawnSize(),
                intent: .guide,
                avoiding: existingFrames,
                focusArea: nil,
                cursorLocation: nil
            )
            window.setFrame(frame, display: true, animate: false)
            hasPositionedInitialFrame = true
        }

        isClosing = false
        isActive = true
        applyRootView()
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        if !window.isVisible {
            PanelMotion.animateIn(window)
        } else {
            window.alphaValue = 1
            window.orderFrontRegardless()
        }
    }

    func hidePanel() {
        guard let window, window.isVisible else { return }
        if isClosing {
            window.orderOut(nil)
            isClosing = false
            isActive = false
            applyRootView()
            return
        }

        isClosing = true
        PanelMotion.animateOut(window) { [weak self] in
            self?.window?.orderOut(nil)
            self?.isActive = false
            self?.applyRootView()
            self?.isClosing = false
        }
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

    private func applyRootView() {
        let rootView = ShortcutsPanelView(isActive: isActive || isPanelVisible) { [weak self] in
            self?.hidePanel()
        }

        if let hostingView {
            hostingView.rootView = rootView
            return
        }

        let hostingView = ShortcutsPanelHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window?.contentView = hostingView
        self.hostingView = hostingView
    }
}

@MainActor
private final class ShortcutsPanelWindow: NSWindow {
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
private final class ShortcutsPanelHostingView: NSHostingView<ShortcutsPanelView> {
    override var mouseDownCanMoveWindow: Bool { false }
}

private struct ShortcutsPanelView: View {
    let isActive: Bool
    let closeHandler: () -> Void
    @State private var isHovered = false
    @State private var isDragging = false

    private let primaryItems: [KeyboardShortcutFeatureItem] = [
        KeyboardShortcutFeatureItem(keys: "Ctrl + Option + L / Space", title: "Open Lumi", subtitle: "Bring up the launcher from anywhere"),
        KeyboardShortcutFeatureItem(keys: "Ctrl + Option + T", title: "Toggle Theater", subtitle: "Enter or exit immersive video mode")
    ]

    private let secondaryItems: [KeyboardShortcutLineItem] = [
        KeyboardShortcutLineItem(keys: "Ctrl + Option + C", label: "Show Shortcuts"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + O", label: "Toggle Panels"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + H", label: "Home"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + P", label: "Play / Pause"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + ← / →", label: "Seek 10s"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + 2", label: "Capture Area")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 18) {
                headerSection

                VStack(spacing: 10) {
                    ForEach(primaryItems) { item in
                        ShortcutFeatureCard(item: item)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Controls")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))

                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(146), spacing: 14, alignment: .leading),
                            GridItem(.flexible(), spacing: 14, alignment: .leading)
                        ],
                        alignment: .leading,
                        spacing: 9
                    ) {
                        ForEach(secondaryItems) { item in
                            ShortcutLineRow(item: item)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 58)
            .padding(.bottom, 18)

            MinimalPanelHeader(
                leading: {
                    FloatingTrafficLightCloseButton(action: closeHandler)
                },
                center: {
                    HStack(spacing: 8) {
                        FloatingPanelBadge(icon: "keyboard", title: "Shortcuts")
                        PanelGripDots()
                    }
                },
                isDragging: $isDragging,
                isActive: true,
                isHovered: isHovered
            )
        }
        .frame(width: 408, height: 336)
        .background(PremiumPanelStyle.contentBedColor)
        .premiumPanelChrome(isActive: isActive, isHovered: isHovered, isDragging: isDragging, usesFilledSurface: true)
        .onHover { isHovered = $0 }
    }

    private var headerSection: some View {
        HStack(spacing: 10) {
            LumiOrbView(size: 18, opacity: 0.96)

            VStack(alignment: .leading, spacing: 2) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))

                Text("A compact workspace reference for Lumi")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ShortcutFeatureCard: View {
    let item: KeyboardShortcutFeatureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(item.keys)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.96))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.23, green: 0.46, blue: 0.74).opacity(0.84),
                            Color(red: 0.14, green: 0.28, blue: 0.48).opacity(0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.96))

                Text(item.subtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.064),
                            Color.white.opacity(0.028)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }
}

private struct ShortcutLineRow: View {
    let item: KeyboardShortcutLineItem

    var body: some View {
        Group {
            Text(item.keys)
                .font(.system(size: 10.4, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.label)
                .font(.system(size: 12.4, weight: .medium))
                .foregroundStyle(.white.opacity(0.84))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct KeyboardShortcutFeatureItem: Identifiable {
    let id = UUID()
    let keys: String
    let title: String
    let subtitle: String
}

private struct KeyboardShortcutLineItem: Identifiable {
    let id = UUID()
    let keys: String
    let label: String
}
