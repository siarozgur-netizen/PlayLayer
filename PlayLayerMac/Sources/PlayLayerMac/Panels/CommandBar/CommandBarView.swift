import AppKit
import SwiftUI

struct CommandBarView: View {
    let actions: [CommandBarAction]
    let executeAction: (CommandBarAction) -> Void
    let executeCommand: (String) -> Bool

    @State private var selectedIndex = 0
    @State private var hoveredIndex: Int?
    @State private var isHovered = false
    @State private var commandText = ""
    @State private var inlineMessage: String?
    private let actionGridColumnCount = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                CommandBarBrandCluster()

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1, height: 34)

                VStack(alignment: .leading, spacing: 8) {
                    CommandBarInputRow(
                        text: $commandText,
                        inlineMessage: inlineMessage,
                        onMoveUp: moveSelectionUp,
                        onMoveDown: moveSelectionDown,
                        onMoveLeft: moveSelectionLeft,
                        onMoveRight: moveSelectionRight,
                        onSubmit: submitCommand,
                        onCancel: {}
                    )

                    CommandBarMetaRow(inlineMessage: inlineMessage)
                }
            }

            if launcherActions.isEmpty {
                CommandBarEmptyState()
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                    alignment: .leading,
                    spacing: 10
                ) {
                    ForEach(Array(launcherActions.enumerated()), id: \.element.id) { index, action in
                        CommandBarPill(
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
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(CommandBarBackdrop())
        .premiumPanelChrome(isActive: true, isHovered: isHovered, usesFilledSurface: true)
        .onHover { isHovered = $0 }
        .onAppear {
            selectedIndex = 0
            hoveredIndex = nil
            commandText = ""
            inlineMessage = nil
        }
        .onChange(of: launcherActions.count) { newCount in
            if newCount == 0 {
                selectedIndex = 0
            } else {
                selectedIndex = min(selectedIndex, newCount - 1)
            }
        }
        .onChange(of: commandText) { _ in
            inlineMessage = nil
        }
        .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: launcherActions.count)
    }

    private var launcherActions: [CommandBarAction] {
        actions
    }

    private func moveSelectionUp() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = max(selectedIndex - actionGridColumnCount, 0)
        hoveredIndex = nil
    }

    private func moveSelectionDown() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = min(selectedIndex + actionGridColumnCount, launcherActions.count - 1)
        hoveredIndex = nil
    }

    private func moveSelectionLeft() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
        hoveredIndex = nil
    }

    private func moveSelectionRight() {
        guard !launcherActions.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, launcherActions.count - 1)
        hoveredIndex = nil
    }

    private func executeSelectedAction() {
        guard launcherActions.indices.contains(selectedIndex) else { return }
        executeAction(launcherActions[selectedIndex])
    }

    private func submitCommand() {
        let trimmed = commandText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            executeSelectedAction()
            return
        }

        if executeCommand(trimmed) {
            commandText = ""
            inlineMessage = nil
        } else {
            inlineMessage = "No matching web command"
        }
    }
}

private struct CommandBarBrandCluster: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                LumiOrbView(size: 24, opacity: 0.96)

                Text("Lumi")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
            }

            Text("Workspace launcher")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(width: 148, alignment: .leading)
    }
}

private struct CommandBarInputRow: View {
    @Binding var text: String
    let inlineMessage: String?
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "command")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.80))
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            CommandBarInputField(
                text: $text,
                placeholder: "Type a web command or URL",
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                onMoveLeft: onMoveLeft,
                onMoveRight: onMoveRight,
                onSubmit: onSubmit,
                onCancel: onCancel
            )
            .frame(height: 24)

            Text("Enter")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.44))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.032))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(inlineMessage == nil ? 0.05 : 0.08), lineWidth: 1)
        }
    }
}

private struct CommandBarMetaRow: View {
    let inlineMessage: String?

    var body: some View {
        HStack(spacing: 12) {
            if let inlineMessage {
                Text(inlineMessage)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            } else {
                Text("Try: open google · yt iron farm tutorial · weather istanbul")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.40))
            }

            Spacer(minLength: 10)

            Text("Ctrl + Option + L/Space")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.34))
        }
        .padding(.horizontal, 4)
    }
}

private struct CommandBarPill: View {
    let action: CommandBarAction
    let isSelected: Bool
    let isHovered: Bool
    let onHover: () -> Void
    let onExit: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(isSelected ? 0.94 : 0.80))

                    Text(displayTitle)
                        .font(.system(size: 12.6, weight: .semibold))
                        .foregroundStyle(.white.opacity(isSelected ? 0.96 : 0.84))
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }

                if let shortcutHint = action.shortcutHint {
                    Text(shortcutHint)
                        .font(.system(size: 9.6, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(isSelected ? 0.58 : 0.34))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(backgroundShape)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            inside ? onHover() : onExit()
        }
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                isSelected
                ? LinearGradient(
                    colors: [
                        Color(red: 0.19, green: 0.38, blue: 0.60).opacity(0.56),
                        Color(red: 0.12, green: 0.22, blue: 0.35).opacity(0.48)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.050 : 0.034),
                        Color.white.opacity(isHovered ? 0.026 : 0.016)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected
                        ? Color.white.opacity(0.09)
                        : Color.white.opacity(isHovered ? 0.050 : 0.032),
                        lineWidth: 1
                    )
            }
    }

    private var symbol: String {
        let text = action.title.lowercased()
        if text.contains("youtube") || text.contains("overlay") { return "play.tv.fill" }
        if text.contains("google") { return "globe" }
        if text.contains("image") { return "photo.fill" }
        if text.contains("pdf") { return "doc.richtext.fill" }
        if text.contains("screen") { return "camera.fill" }
        if text.contains("area") { return "selection.pin.in.out" }
        if text.contains("shortcut") || text.contains("guide") { return "keyboard" }
        if text.contains("quit") { return "power" }
        return "bolt.fill"
    }

    private var displayTitle: String {
        switch action.title {
        case "Open YouTube Overlay":
            return "YouTube"
        case "Open Google":
            return "Google"
        case "Open Image Panel...":
            return "Image Panel"
        case "Open PDF Panel...":
            return "PDF Panel"
        case "Capture Screen to Panel":
            return "Capture Screen"
        case "Capture Area to Panel":
            return "Capture Area"
        case "Show Keyboard Shortcuts":
            return "Shortcuts"
        case "Quit Lumi":
            return "Quit"
        default:
            return action.title
        }
    }
}

private struct CommandBarEmptyState: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.022))
            .frame(height: 92)
            .overlay {
                Text("No actions available")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
            }
    }
}

private struct CommandBarBackdrop: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(0.30))
            }
    }
}

private struct CommandBarInputField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> CommandBarInputNSTextField {
        let field = CommandBarInputNSTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 14.5, weight: .medium)
        field.textColor = .white.withAlphaComponent(0.96)
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.34),
                .font: NSFont.systemFont(ofSize: 14.5, weight: .medium)
            ]
        )
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail
        return field
    }

    func updateNSView(_ nsView: CommandBarInputNSTextField, context: Context) {
        context.coordinator.text = $text

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        nsView.onMoveUp = onMoveUp
        nsView.onMoveDown = onMoveDown
        nsView.onMoveLeft = onMoveLeft
        nsView.onMoveRight = onMoveRight
        nsView.onSubmit = onSubmit
        nsView.onCancel = onCancel
        nsView.scheduleFocus()
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            text.wrappedValue = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            _ = textView
            guard let field = control as? CommandBarInputNSTextField else {
                return false
            }

            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)):
                field.onMoveUp?()
                return true
            case #selector(NSResponder.moveDown(_:)):
                field.onMoveDown?()
                return true
            case #selector(NSResponder.moveLeft(_:)):
                field.onMoveLeft?()
                return true
            case #selector(NSResponder.moveRight(_:)):
                field.onMoveRight?()
                return true
            case #selector(NSResponder.insertNewline(_:)):
                field.onSubmit?()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                field.onCancel?()
                field.window?.cancelOperation(nil)
                return true
            default:
                return false
            }
        }
    }
}

@MainActor
private final class CommandBarInputNSTextField: NSTextField {
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    func scheduleFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window else { return }
            guard window.firstResponder !== currentEditor() else { return }
            window.makeFirstResponder(self)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleFocus()
    }
}
