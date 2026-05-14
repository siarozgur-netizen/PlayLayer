import AppKit
import SwiftUI

enum PremiumPanelStyle {
    static let cornerRadius: CGFloat = 17
    static let contentInset: CGFloat = 1.5
    static let contentCornerRadius: CGFloat = 15.5
    static let floatingChromePadding: CGFloat = 7
    static let floatingChromeSpacing: CGFloat = 8
    static let headerHorizontalPadding: CGFloat = 11
    static let headerTopPadding: CGFloat = 11
    static let dragSurfaceHeight: CGFloat = 40
    static let iconButtonSize: CGFloat = 28
    static let iconButtonFontSize: CGFloat = 11
    static let badgeIconFontSize: CGFloat = 10
    static let badgeFontSize: CGFloat = 11
    static let badgeHorizontalPadding: CGFloat = 9
    static let badgeVerticalPadding: CGFloat = 6
    static let hoverAnimationDuration: Double = 0.12
    static let activeAnimationDuration: Double = 0.16
    static let dragAnimationDuration: Double = 0.10
    static let chromeBorderOpacity: Double = 0.05
    static let iconButtonBorderOpacity: Double = 0.07
    static let badgeFillOpacity: Double = 0.30
    static let chromeFillOpacity: Double = 0.22
    static let iconButtonFillOpacity: Double = 0.40
    static let filledSurfaceActiveOpacity: Double = 0.66
    static let filledSurfaceInactiveOpacity: Double = 0.62
    static let defaultShadowOpacity: Double = 0.095
    static let hoverShadowOpacity: Double = 0.115
    static let activeShadowOpacity: Double = 0.135
    static let dragShadowOpacity: Double = 0.17
    static let defaultShadowRadius: CGFloat = 28
    static let hoverShadowRadius: CGFloat = 32
    static let activeShadowRadius: CGFloat = 36
    static let dragShadowRadius: CGFloat = 40
    static let defaultShadowYOffset: CGFloat = 10
    static let hoverShadowYOffset: CGFloat = 12
    static let activeShadowYOffset: CGFloat = 14
    static let dragShadowYOffset: CGFloat = 18
    static let contentEdgeShadowOpacity: Double = 0.17
    static let contentEdgeHighlightOpacity: Double = 0.05
    static let panelSurfaceColor = Color(red: 0.055, green: 0.057, blue: 0.063)
    static let contentBedColor = Color(red: 0.060, green: 0.062, blue: 0.070)
    static let platformPanelSurfaceColor = NSColor(calibratedRed: 0.055, green: 0.057, blue: 0.063, alpha: 1.0)
    static let platformContentBedColor = NSColor(calibratedRed: 0.060, green: 0.062, blue: 0.070, alpha: 1.0)
}

struct FloatingPanelBadge: View {
    let icon: String?
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: PremiumPanelStyle.badgeIconFontSize, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.84))
            }

            Text(title)
                .font(.system(size: PremiumPanelStyle.badgeFontSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, PremiumPanelStyle.badgeHorizontalPadding)
        .padding(.vertical, PremiumPanelStyle.badgeVerticalPadding)
        .background(Color.black.opacity(PremiumPanelStyle.badgeFillOpacity))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(PremiumPanelStyle.chromeBorderOpacity), lineWidth: 1)
        }
    }
}

struct FloatingPanelIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: PremiumPanelStyle.iconButtonFontSize, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: PremiumPanelStyle.iconButtonSize, height: PremiumPanelStyle.iconButtonSize)
                .background(Color.black.opacity(PremiumPanelStyle.iconButtonFillOpacity))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(PremiumPanelStyle.iconButtonBorderOpacity), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct FloatingTrafficLightCloseButton: View {
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.42, blue: 0.38),
                            Color(red: 0.90, green: 0.20, blue: 0.19)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(isHovered ? 0.26 : 0.14), lineWidth: 0.8)
                }
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(.black.opacity(isHovered ? 0.72 : 0.56))
                        .opacity(isHovered ? 1 : 0.82)
                }
                .frame(width: 16, height: 16)
                .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.05 : 1))
                .shadow(color: .black.opacity(isHovered ? 0.22 : 0.16), radius: isHovered ? 4 : 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

struct FloatingPanelChromeContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            content
        }
        .padding(PremiumPanelStyle.floatingChromePadding)
        .background(Color.black.opacity(PremiumPanelStyle.chromeFillOpacity))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(PremiumPanelStyle.chromeBorderOpacity), lineWidth: 1)
        }
    }
}

struct PanelDragSurfaceView: NSViewRepresentable {
    @Binding var isDragging: Bool

    func makeNSView(context: Context) -> PanelDragSurfaceNSView {
        let view = PanelDragSurfaceNSView()
        view.dragStateChanged = { isDragging in
            if self.isDragging != isDragging {
                self.isDragging = isDragging
            }
        }
        return view
    }

    func updateNSView(_ nsView: PanelDragSurfaceNSView, context: Context) {
        _ = context
        nsView.dragStateChanged = { isDragging in
            if self.isDragging != isDragging {
                self.isDragging = isDragging
            }
        }
        nsView.needsDisplay = true
    }
}

@MainActor
final class PanelDragSurfaceNSView: NSView {
    var dragStateChanged: ((Bool) -> Void)?
    private var isHovered = false
    private var isPressed = false
    private var trackingArea: NSTrackingArea?
    private var dragStartLocation: NSPoint?
    private var dragStartFrame: CGRect?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: isPressed ? .closedHand : .openHand)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let trackingArea = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        _ = event
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        _ = event
        guard !isPressed else { return }
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        isPressed = true
        dragStateChanged?(true)
        dragStartLocation = NSEvent.mouseLocation
        dragStartFrame = window.frame
        window.invalidateCursorRects(for: self)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        _ = event
        guard
            let window,
            let dragStartLocation,
            let dragStartFrame
        else {
            return
        }

        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - dragStartLocation.x
        let deltaY = currentLocation.y - dragStartLocation.y

        let targetFrame = CGRect(
            x: dragStartFrame.origin.x + deltaX,
            y: dragStartFrame.origin.y + deltaY,
            width: dragStartFrame.width,
            height: dragStartFrame.height
        )

        window.setFrame(targetFrame, display: true, animate: false)
    }

    override func mouseUp(with event: NSEvent) {
        _ = event
        defer {
            isPressed = false
            dragStateChanged?(false)
            isHovered = bounds.contains(convert(event.locationInWindow, from: nil))
            dragStartLocation = nil
            dragStartFrame = nil
            window?.invalidateCursorRects(for: self)
            needsDisplay = true
        }

        guard
            let window,
            let visibleFrame = window.screen?.visibleFrame
        else {
            return
        }

        let adjustedFrame = PanelSnapService.adjustedFrame(for: window.frame, in: visibleFrame)
        guard !window.frame.integral.equalTo(adjustedFrame.integral) else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(adjustedFrame, display: true)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let fillAlpha: CGFloat
        switch (isPressed, isHovered) {
        case (true, _):
            fillAlpha = 0.12
        case (false, true):
            fillAlpha = 0.07
        default:
            fillAlpha = 0.03
        }

        NSColor.white.withAlphaComponent(fillAlpha).setFill()
        NSBezierPath(roundedRect: dirtyRect, xRadius: 10, yRadius: 10).fill()
    }
}

struct MinimalPanelHeader<Leading: View, Center: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let center: Center
    @Binding var isDragging: Bool
    let visible: Bool

    var body: some View {
        ZStack(alignment: .top) {
            PanelDragSurfaceView(isDragging: $isDragging)
                .frame(maxWidth: .infinity)
                .frame(height: PremiumPanelStyle.dragSurfaceHeight)

            HStack(spacing: 10) {
                FloatingPanelChromeContainer {
                    leading
                }

                Spacer()

                FloatingPanelChromeContainer {
                    center
                }

                Spacer()

                Color.clear
                    .frame(width: 36, height: 16)
            }
            .padding(.horizontal, PremiumPanelStyle.headerHorizontalPadding)
            .padding(.top, PremiumPanelStyle.headerTopPadding)
        }
        .opacity(visible ? 1 : 0)
        .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: visible)
    }
}

struct PanelGripDots: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PremiumPanelChromeModifier: ViewModifier {
    let isActive: Bool
    let isHovered: Bool
    let isDragging: Bool
    let usesFilledSurface: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: PremiumPanelStyle.cornerRadius, style: .continuous)

        content
            .clipShape(shape)
            .background {
                if usesFilledSurface {
                    shape
                        .fill(PremiumPanelStyle.panelSurfaceColor.opacity(isActive ? PremiumPanelStyle.filledSurfaceActiveOpacity : PremiumPanelStyle.filledSurfaceInactiveOpacity))
                }
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                borderLeadColor,
                                borderTrailColor,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isActive ? 0.9 : 0.75
                    )
                    .padding(PremiumPanelStyle.contentInset)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(isActive ? 0.034 : 0.018), lineWidth: 0.55)
                    .padding(PremiumPanelStyle.contentInset)
            }
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowYOffset
            )
            .animation(.easeOut(duration: PremiumPanelStyle.activeAnimationDuration), value: isActive)
            .animation(.easeOut(duration: PremiumPanelStyle.hoverAnimationDuration), value: isHovered)
            .animation(.easeOut(duration: PremiumPanelStyle.dragAnimationDuration), value: isDragging)
    }

    private var borderLeadColor: Color {
        if isDragging {
            return Color(red: 0.60, green: 0.86, blue: 1.0).opacity(0.48)
        }

        if isActive {
            return Color.white.opacity(0.12)
        }

        if isHovered {
            return Color.white.opacity(0.075)
        }

        return Color.white.opacity(0.045)
    }

    private var borderTrailColor: Color {
        if isDragging {
            return Color.white.opacity(0.12)
        }

        if isActive {
            return Color.white.opacity(0.05)
        }

        if isHovered {
            return Color.white.opacity(0.035)
        }

        return Color.white.opacity(0.015)
    }

    private var shadowOpacity: Double {
        if isDragging { return PremiumPanelStyle.dragShadowOpacity }
        if isActive { return PremiumPanelStyle.activeShadowOpacity }
        if isHovered { return PremiumPanelStyle.hoverShadowOpacity }
        return PremiumPanelStyle.defaultShadowOpacity
    }

    private var shadowRadius: CGFloat {
        if isDragging { return PremiumPanelStyle.dragShadowRadius }
        if isActive { return PremiumPanelStyle.activeShadowRadius }
        if isHovered { return PremiumPanelStyle.hoverShadowRadius }
        return PremiumPanelStyle.defaultShadowRadius
    }

    private var shadowYOffset: CGFloat {
        if isDragging { return PremiumPanelStyle.dragShadowYOffset }
        if isActive { return PremiumPanelStyle.activeShadowYOffset }
        if isHovered { return PremiumPanelStyle.hoverShadowYOffset }
        return PremiumPanelStyle.defaultShadowYOffset
    }
}

struct PanelContentIntegrationModifier: ViewModifier {
    let fillColor: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: PremiumPanelStyle.contentCornerRadius, style: .continuous)

        content
            .clipShape(shape)
            .background {
                if let fillColor {
                    shape.fill(fillColor)
                }
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(0.024), lineWidth: 0.6)
            }
            .overlay {
                shape
                    .stroke(Color.black.opacity(PremiumPanelStyle.contentEdgeShadowOpacity), lineWidth: 5.5)
                    .blur(radius: 4.5)
                    .mask(shape)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(PremiumPanelStyle.contentEdgeHighlightOpacity), lineWidth: 1.4)
                    .blur(radius: 1.2)
                    .mask(shape)
                    .opacity(0.72)
            }
    }
}

extension View {
    func premiumPanelChrome(isActive: Bool, isHovered: Bool = false, isDragging: Bool = false, usesFilledSurface: Bool = false) -> some View {
        modifier(PremiumPanelChromeModifier(isActive: isActive, isHovered: isHovered, isDragging: isDragging, usesFilledSurface: usesFilledSurface))
    }

    func integratedPanelContent(fillColor: Color? = PremiumPanelStyle.contentBedColor) -> some View {
        modifier(PanelContentIntegrationModifier(fillColor: fillColor))
    }
}
