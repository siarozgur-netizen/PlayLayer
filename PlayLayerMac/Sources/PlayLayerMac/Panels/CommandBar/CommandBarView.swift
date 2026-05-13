import SwiftUI

struct CommandBarView: View {
    let actions: [CommandBarAction]
    let executeAction: (CommandBarAction) -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @State private var hoveredIndex: Int?
    @State private var isHovered = false
    @FocusState private var queryFieldFocused: Bool

    private var filteredActions: [CommandBarAction] {
        actions.filter { $0.matches(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PremiumPanelStyle.headerTopPadding + 1) {
            CommandBarHeader()

            VStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 1) {
                CommandBarSearchField(query: $query)
                    .focused($queryFieldFocused)
                    .onSubmit {
                        executeSelectedAction()
                    }

                if filteredActions.isEmpty {
                    CommandBarEmptyState(query: query)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScrollView {
                        VStack(spacing: PremiumPanelStyle.floatingChromeSpacing - 1) {
                            ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
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
                        .padding(.top, 2)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: 198)
                    .transition(.opacity)
                }
            }

            CommandBarFooter()
        }
        .padding(.horizontal, PremiumPanelStyle.cornerRadius - 1)
        .padding(.vertical, PremiumPanelStyle.cornerRadius - 2)
        .frame(width: 462)
        .background(CommandBarBackdrop())
        .premiumPanelChrome(isActive: true, isHovered: isHovered, usesFilledSurface: true)
        .onHover { isHovered = $0 }
        .onAppear {
            selectedIndex = 0
            hoveredIndex = nil
            DispatchQueue.main.async {
                queryFieldFocused = true
            }
        }
        .onChange(of: query) { _ in
            selectedIndex = 0
            hoveredIndex = nil
        }
        .onChange(of: filteredActions.count) { newCount in
            if newCount == 0 {
                selectedIndex = 0
            } else {
                selectedIndex = min(selectedIndex, newCount - 1)
            }
        }
        .onMoveCommand { direction in
            guard !filteredActions.isEmpty else { return }
            switch direction {
            case .down:
                selectedIndex = min(selectedIndex + 1, filteredActions.count - 1)
                hoveredIndex = nil
            case .up:
                selectedIndex = max(selectedIndex - 1, 0)
                hoveredIndex = nil
            default:
                break
            }
        }
        .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: query)
        .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: filteredActions.count)
    }

    private func executeSelectedAction() {
        guard filteredActions.indices.contains(selectedIndex) else { return }
        executeAction(filteredActions[selectedIndex])
    }
}

private struct CommandBarHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
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
                    .foregroundStyle(.white.opacity(0.44))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Search commands")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.97))

                Text("Panels, captures, files, and shortcuts")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.50))
            }
        }
    }
}

private struct CommandBarSearchField: View {
    @Binding var query: String

    var body: some View {
        HStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.50))

            TextField("Type a command…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.058))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.065), lineWidth: 1)
        }
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
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((isSelected ? Color.white.opacity(0.11) : Color.white.opacity(0.04)))
                        .frame(width: 34, height: 34)

                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .lineLimit(1)

                    Text(keywordText)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.50))
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Text("Enter")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(backgroundShape)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            inside ? onHover() : onExit()
        }
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                isSelected
                ? LinearGradient(
                    colors: [
                        Color(red: 0.19, green: 0.43, blue: 0.68).opacity(0.70),
                        Color(red: 0.14, green: 0.26, blue: 0.42).opacity(0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                : LinearGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.065 : 0.04),
                        Color.white.opacity(isHovered ? 0.035 : 0.022)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                        ? Color.white.opacity(0.14)
                        : Color.white.opacity(isHovered ? 0.065 : 0.04),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(isSelected ? 0.14 : 0.06),
                radius: isSelected ? 10 : 5,
                x: 0,
                y: isSelected ? 7 : 3
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
    let query: String

    var body: some View {
        VStack(spacing: PremiumPanelStyle.floatingChromeSpacing + 2) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.white.opacity(0.58))

            Text("No matching actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            if !query.isEmpty {
                Text("Try a broader keyword like image, pdf, or capture")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
        HStack(spacing: 14) {
            Text("↑ ↓ Move")
            Text("Enter Run")
            Text("Esc Close")
            Spacer()
        }
        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.44))
    }
}

private struct CommandBarBackdrop: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.black.opacity(0.72))
    }
}
