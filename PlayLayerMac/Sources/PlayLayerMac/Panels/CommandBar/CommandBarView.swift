import AppKit
import SwiftUI

struct CommandBarView: View {
    let actions: [CommandBarAction]
    let executeAction: (CommandBarAction) -> Void

    @State private var selectedIndex = 0
    @State private var hoveredIndex: Int?
    @State private var isHovered = false

    private var shortcutsAction: CommandBarAction? {
        actions.first { $0.title == "Show Keyboard Shortcuts" }
    }

    private var launcherActions: [CommandBarAction] {
        actions.filter { $0.title != "Show Keyboard Shortcuts" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PremiumPanelStyle.headerTopPadding + 5) {
            CommandBarHeader()

            if let shortcutsAction {
                CommandBarUtilityRow(action: shortcutsAction) {
                    executeAction(shortcutsAction)
                }
            }

            if launcherActions.isEmpty {
                CommandBarEmptyState()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollView {
                    VStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 3) {
                        ForEach(Array(launcherActions.enumerated()), id: \.element.id) { index, action in
                            CommandBarRow(
                                action: action,
                                isSelected: index == selectedIndex,
                                isHovered: hoveredIndex == index
                            ) {
                                hoveredIndex = index
                            } onExit: {
                                if hoveredIndex == index {
                                    hoveredIndex = nil
                                }
                            } onTap: {
                                executeAction(action)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 264)
                .transition(.opacity)
            }

            CommandBarFooter()
        }
        .padding(.horizontal, PremiumPanelStyle.cornerRadius)
        .padding(.vertical, PremiumPanelStyle.cornerRadius + 3)
        .frame(width: 462)
        .background(CommandBarBackdrop())
        .background(
            CommandBarKeyCaptureView(
                onMoveUp: moveSelectionUp,
                onMoveDown: moveSelectionDown,
                onConfirm: executeSelectedAction,
                onCancel: {}
            )
            .frame(width: 0, height: 0)
        )
        .premiumPanelChrome(isActive: true, isHovered: isHovered, usesFilledSurface: true)
        .onHover { isHovered = $0 }
        .onAppear {
            selectedIndex = 0
            hoveredIndex = nil
        }
        .onChange(of: launcherActions.count) { newCount in
            if newCount == 0 {
                selectedIndex = 0
            } else {
                selectedIndex = min(selectedIndex, newCount - 1)
            }
        }
        .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: launcherActions.count)
    }

    private func moveSelectionUp() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
        hoveredIndex = nil
    }

    private func moveSelectionDown() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, launcherActions.count - 1)
        hoveredIndex = nil
    }

    private func executeSelectedAction() {
        guard launcherActions.indices.contains(selectedIndex) else { return }
        executeAction(launcherActions[selectedIndex])
    }
}

private struct CommandBarHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 8) {
                    LumiOrbView(size: 18, opacity: 0.94)

                    Text("Lumi")
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }

                Spacer()

                Text("Ctrl + Option + L/Space")
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.40))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Actions")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.97))

                Text("Keyboard-first workspace controls")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
    }
}

private struct CommandBarUtilityRow: View {
    let action: CommandBarAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                Image(systemName: "keyboard")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text(action.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                if let shortcutHint = action.shortcutHint {
                    Text(shortcutHint)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.52))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CommandBarRow: View {
    let action: CommandBarAction
    let isSelected: Bool
    let isHovered: Bool
    let onHover: () -> Void
    let onExit: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.11) : Color.white.opacity(0.04))
                        .frame(width: 34, height: 34)

                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineLimit(1)

                    Text(keywordText)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                if let shortcutHint = action.shortcutHint {
                    Text(shortcutHint)
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(isSelected ? 0.70 : 0.46))
                        .frame(minWidth: 74, alignment: .trailing)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(backgroundShape)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            inside ? onHover() : onExit()
        }
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(
                isSelected
                ? LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.40, blue: 0.63).opacity(0.62),
                        Color(red: 0.13, green: 0.24, blue: 0.38).opacity(0.54)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.058 : 0.036),
                        Color.white.opacity(isHovered ? 0.030 : 0.018)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isSelected
                        ? Color.white.opacity(0.11)
                        : Color.white.opacity(isHovered ? 0.054 : 0.034),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(isSelected ? 0.11 : 0.05),
                radius: isSelected ? 9 : 4,
                x: 0,
                y: isSelected ? 6 : 3
            )
    }

    private var keywordText: String {
        action.keywords.prefix(3).joined(separator: " · ")
    }

    private var symbol: String {
        let text = action.title.lowercased()
        if text.contains("youtube") || text.contains("overlay") { return "play.tv.fill" }
        if text.contains("image") { return "photo.fill" }
        if text.contains("pdf") { return "doc.richtext.fill" }
        if text.contains("screen") { return "camera.fill" }
        if text.contains("area") { return "selection.pin.in.out" }
        return "bolt.fill"
    }
}

private struct CommandBarEmptyState: View {
    var body: some View {
        VStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 2) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white.opacity(0.54))

            Text("No actions available")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.022))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        }
    }
}

private struct CommandBarFooter: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("↑ ↓ Move")
            Text("·")
            Text("Enter Run")
            Text("·")
            Text("Esc Close")
            Spacer()
        }
        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.38))
        .padding(.top, 2)
    }
}

private struct CommandBarBackdrop: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.72))
    }
}

private struct CommandBarKeyCaptureView: NSViewRepresentable {
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> CommandBarKeyCaptureNSView {
        let view = CommandBarKeyCaptureNSView()
        view.onMoveUp = onMoveUp
        view.onMoveDown = onMoveDown
        view.onConfirm = onConfirm
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: CommandBarKeyCaptureNSView, context: Context) {
        _ = context
        nsView.onMoveUp = onMoveUp
        nsView.onMoveDown = onMoveDown
        nsView.onConfirm = onConfirm
        nsView.onCancel = onCancel
        nsView.scheduleFocus()
    }
}

@MainActor
private final class CommandBarKeyCaptureNSView: NSView {
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleFocus()
    }

    func scheduleFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window, window.firstResponder !== self else { return }
            window.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 125:
            onMoveDown?()
        case 126:
            onMoveUp?()
        case 36, 76:
            onConfirm?()
        case 53:
            onCancel?()
            window?.cancelOperation(nil)
        default:
            super.keyDown(with: event)
        }
    }
}
