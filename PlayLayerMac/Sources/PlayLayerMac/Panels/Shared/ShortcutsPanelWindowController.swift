import AppKit
import SwiftUI

@MainActor
final class ShortcutsPanelWindowController: NSWindowController {
    private var hideWorkItem: DispatchWorkItem?
    private var isClosing = false

    init() {
        let window = NSWindow(
            contentRect: Self.defaultFrame(),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true

        super.init(window: window)
        applyRootView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPanel() {
        hideWorkItem?.cancel()
        isClosing = false
        applyRootView()

        guard let window else { return }
        window.setFrame(Self.defaultFrame(), display: true, animate: false)
        window.orderFrontRegardless()
        PanelMotion.animateCommandBarIn(window)

        let workItem = DispatchWorkItem { [weak self] in
            self?.hidePanel()
        }

        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8, execute: workItem)
    }

    func hidePanel() {
        guard let window, window.isVisible, !isClosing else { return }
        isClosing = true
        PanelMotion.animateCommandBarOut(window) { [weak self] in
            self?.window?.orderOut(nil)
            self?.isClosing = false
        }
    }

    private func applyRootView() {
        let hostingView = NSHostingView(rootView: ShortcutsPanelView())
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window?.contentView = hostingView
    }

    private static func defaultFrame() -> CGRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 452
        let height: CGFloat = 304
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.midY - (height / 2) + 12
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

private struct ShortcutsPanelView: View {
    private let primaryItems: [KeyboardShortcutFeatureItem] = [
        KeyboardShortcutFeatureItem(keys: "Ctrl + Option + L / Space", title: "Open Lumi", subtitle: "Bring up the action launcher"),
        KeyboardShortcutFeatureItem(keys: "Ctrl + Option + T", title: "Toggle Theater", subtitle: "Enter or exit immersive video mode")
    ]

    private let secondaryItems: [KeyboardShortcutLineItem] = [
        KeyboardShortcutLineItem(keys: "Ctrl + Option + O", label: "Toggle Panels"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + H", label: "Home"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + P", label: "Play / Pause"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + ← / →", label: "Seek 10s"),
        KeyboardShortcutLineItem(keys: "Ctrl + Option + 2", label: "Capture Area")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                LumiOrbView(size: 18, opacity: 0.96)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lumi Shortcuts")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))

                    Text("Keyboard-first workspace controls")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()

                Text("Auto closes")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
            }

            VStack(spacing: 10) {
                ForEach(primaryItems) { item in
                    ShortcutFeatureCard(item: item)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(secondaryItems) { item in
                    ShortcutLineRow(item: item)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .frame(width: 452)
        .background(ShortcutsPanelBackdrop())
        .premiumPanelChrome(isActive: true, isHovered: false, usesFilledSurface: true)
    }
}

private struct ShortcutFeatureCard: View {
    let item: KeyboardShortcutFeatureItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.keys)
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.96))
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.23, green: 0.46, blue: 0.74).opacity(0.88),
                            Color(red: 0.14, green: 0.28, blue: 0.48).opacity(0.84)
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
                            Color.white.opacity(0.075),
                            Color.white.opacity(0.036)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct ShortcutLineRow: View {
    let item: KeyboardShortcutLineItem

    var body: some View {
        HStack(spacing: 10) {
            Text(item.keys)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.60))
                .frame(width: 138, alignment: .leading)

            Text(item.label)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))

            Spacer(minLength: 0)
        }
    }
}

private struct ShortcutsPanelBackdrop: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.76))
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
