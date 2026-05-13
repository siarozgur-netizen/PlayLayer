import AppKit
import SwiftUI

@MainActor
final class StartupIdentityWindowController: NSWindowController {
    private var isVisible = false
    private var completionWorkItem: DispatchWorkItem?

    init() {
        let frame = StartupIdentityWindowController.defaultFrame()
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = true

        super.init(window: window)
        applyRootView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showThenDismiss(after delay: TimeInterval = 0.72, completion: @escaping @MainActor () -> Void) {
        guard let window else { return }

        completionWorkItem?.cancel()
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.alphaValue = 0
        window.setFrame(Self.defaultFrame(), display: false)
        window.makeKeyAndOrderFront(nil)
        isVisible = true

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, let window = self.window else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    self.window?.orderOut(nil)
                    self.isVisible = false
                    completion()
                }
            })
        }

        completionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func applyRootView() {
        let hostingView = NSHostingView(rootView: StartupIdentityView())
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        window?.contentView = hostingView
    }

    private static func defaultFrame() -> CGRect {
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let width: CGFloat = 232
        let height: CGFloat = 228
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.midY - (height / 2) + 18
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

private struct StartupIdentityView: View {
    var body: some View {
        VStack(spacing: 14) {
            LumiOrbView(size: 112, opacity: 0.98)

            VStack(spacing: 5) {
                Text("Lumi")
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))

                Text("A calm workspace layer")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.44))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.38))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 14)
        .padding(24)
    }
}
