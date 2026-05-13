import AppKit

@MainActor
final class PanelLayoutService {
    enum AuxiliaryPanelSpawnIntent {
        case genericImage
        case screenshot
        case pdf
    }

    private let browseWidthRatio: CGFloat = 0.30
    private let theaterWidthRatio: CGFloat = 0.32
    private let browseAspectRatio: CGFloat = 16.0 / 10.0
    private let theaterAspectRatio: CGFloat = 16.0 / 9.0
    private let horizontalMarginRatio: CGFloat = 0.03
    private let verticalMarginRatio: CGFloat = 0.03
    private let imagePanelCascadeOffset: CGFloat = 24
    private let imagePanelCascadeSteps = 6
    private let auxiliaryPanelMargin: CGFloat = 18
    private var nextImagePanelCascadeIndex = 0

    func browseFrame() -> CGRect {
        frame(forWidthRatio: browseWidthRatio, aspectRatio: browseAspectRatio)
    }

    func theaterFrame() -> CGRect {
        frame(forWidthRatio: theaterWidthRatio, aspectRatio: theaterAspectRatio)
    }

    func imagePanelFrame() -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let width = screen.width * 0.22
        let height = width / (16.0 / 10.0)
        let leftMargin = screen.width * 0.04
        let topMargin = screen.height * verticalMarginRatio
        let x = screen.minX + leftMargin
        let y = screen.maxY - topMargin - height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    func imagePanelSpawnSize() -> CGSize {
        imagePanelFrame().size
    }

    func imagePanelSpawnSize(for image: NSImage) -> CGSize {
        let fallbackSize = imagePanelSpawnSize()
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)

        let naturalWidth = image.size.width > 0 ? image.size.width : fallbackSize.width
        let naturalHeight = image.size.height > 0 ? image.size.height : fallbackSize.height

        guard naturalWidth > 0, naturalHeight > 0 else {
            return fallbackSize
        }

        let maxWidth = min(screen.width * 0.46, 980)
        let maxHeight = min(screen.height * 0.58, 780)
        let widthScale = maxWidth / naturalWidth
        let heightScale = maxHeight / naturalHeight
        let downscale = min(widthScale, heightScale, 1.0)

        var width = naturalWidth * downscale
        var height = naturalHeight * downscale

        let aspectRatio = naturalWidth / naturalHeight
        if width < 140 || height < 110 {
            if aspectRatio >= 1 {
                height = max(110, height)
                width = max(140, height * aspectRatio)
            } else {
                width = max(110, width)
                height = max(140, width / aspectRatio)
            }
        }

        width = min(width, maxWidth)
        height = min(height, maxHeight)

        return CGSize(width: width.rounded(.up), height: height.rounded(.up))
    }

    func pdfPanelSpawnSize() -> CGSize {
        let baseSize = imagePanelSpawnSize()
        return CGSize(width: baseSize.width * 1.22, height: baseSize.height * 1.26)
    }

    func nextImagePanelFrame() -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let baseFrame = imagePanelFrame()
        let cascadeIndex = nextImagePanelCascadeIndex
        nextImagePanelCascadeIndex = (nextImagePanelCascadeIndex + 1) % imagePanelCascadeSteps

        let offsetX = CGFloat(cascadeIndex) * imagePanelCascadeOffset
        let offsetY = CGFloat(cascadeIndex) * imagePanelCascadeOffset
        let width = baseFrame.width
        let height = baseFrame.height
        let minX = screen.minX + 12
        let maxX = screen.maxX - width - 12
        let minY = screen.minY + 12
        let maxY = screen.maxY - height - 12
        let proposedX = min(max(baseFrame.origin.x + offsetX, minX), maxX)
        let proposedY = min(max(baseFrame.origin.y - offsetY, minY), maxY)

        return CGRect(x: proposedX, y: proposedY, width: width, height: height)
    }

    func nextAuxiliaryPanelFrame(
        size: CGSize,
        intent: AuxiliaryPanelSpawnIntent,
        avoiding existingFrames: [CGRect],
        focusArea: CGRect? = nil,
        cursorLocation: CGPoint? = nil
    ) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let clampedSize = CGSize(
            width: min(size.width, screen.width - (auxiliaryPanelMargin * 2)),
            height: min(size.height, screen.height - (auxiliaryPanelMargin * 2))
        )

        let fallbackFrame = constrainedFrame(
            nextImagePanelFrame().withSize(clampedSize),
            within: screen
        )

        let focusRect = focusArea.map { constrainedFrame($0, within: screen) }
        let candidates = candidateFrames(
            for: clampedSize,
            in: screen,
            intent: intent,
            focusArea: focusRect
        )

        let cursor = cursorLocation
        let ranked = candidates.map { frame in
            (frame: constrainedFrame(frame, within: screen), score: spawnScore(for: frame, existingFrames: existingFrames, cursorLocation: cursor))
        }

        if let bestCandidate = ranked.min(by: { $0.score < $1.score }), bestCandidate.score < spawnScore(for: fallbackFrame, existingFrames: existingFrames, cursorLocation: cursor) {
            return bestCandidate.frame
        }

        return fallbackFrame
    }

    func constrainedAuxiliaryFrame(_ frame: CGRect) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        return constrainedFrame(frame, within: screen)
    }

    func fullscreenOverlayFrame() -> CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
    }

    private func frame(forWidthRatio widthRatio: CGFloat, aspectRatio: CGFloat) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let width = screen.width * widthRatio
        let height = width / aspectRatio
        let rightMargin = screen.width * horizontalMarginRatio
        let topMargin = screen.height * verticalMarginRatio
        let x = screen.maxX - rightMargin - width
        let y = screen.maxY - topMargin - height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func candidateFrames(
        for size: CGSize,
        in screen: CGRect,
        intent: AuxiliaryPanelSpawnIntent,
        focusArea: CGRect?
    ) -> [CGRect] {
        let topLeft = CGRect(
            x: screen.minX + auxiliaryPanelMargin,
            y: screen.maxY - auxiliaryPanelMargin - size.height,
            width: size.width,
            height: size.height
        )
        let topRight = CGRect(
            x: screen.maxX - auxiliaryPanelMargin - size.width,
            y: screen.maxY - auxiliaryPanelMargin - size.height,
            width: size.width,
            height: size.height
        )
        let lowerLeft = CGRect(
            x: screen.minX + auxiliaryPanelMargin,
            y: screen.minY + auxiliaryPanelMargin,
            width: size.width,
            height: size.height
        )
        let centerRight = CGRect(
            x: screen.maxX - auxiliaryPanelMargin - size.width,
            y: screen.midY - (size.height / 2),
            width: size.width,
            height: size.height
        )

        var candidates: [CGRect] = []

        if let focusArea {
            candidates.append(
                CGRect(
                    x: focusArea.maxX + auxiliaryPanelMargin,
                    y: focusArea.maxY - size.height,
                    width: size.width,
                    height: size.height
                )
            )
            candidates.append(
                CGRect(
                    x: focusArea.minX - auxiliaryPanelMargin - size.width,
                    y: focusArea.maxY - size.height,
                    width: size.width,
                    height: size.height
                )
            )
            candidates.append(
                CGRect(
                    x: focusArea.midX - (size.width / 2),
                    y: focusArea.maxY + auxiliaryPanelMargin,
                    width: size.width,
                    height: size.height
                )
            )
        }

        switch intent {
        case .screenshot:
            candidates.append(contentsOf: [topRight, centerRight, topLeft, lowerLeft])
        case .pdf:
            candidates.append(contentsOf: [centerRight, topRight, topLeft, lowerLeft])
        case .genericImage:
            candidates.append(contentsOf: [topLeft, topRight, centerRight, lowerLeft])
        }

        return candidates
    }

    private func spawnScore(for frame: CGRect, existingFrames: [CGRect], cursorLocation: CGPoint?) -> CGFloat {
        let overlapPenalty = existingFrames.reduce(CGFloat.zero) { partial, existingFrame in
            partial + (frame.intersection(existingFrame).isNull ? 0 : frame.intersection(existingFrame).area)
        }

        let cursorPenalty: CGFloat
        if let cursorLocation, frame.contains(cursorLocation) {
            cursorPenalty = 80_000
        } else if let cursorLocation {
            cursorPenalty = max(0, 220 - hypot(frame.midX - cursorLocation.x, frame.midY - cursorLocation.y))
        } else {
            cursorPenalty = 0
        }

        return overlapPenalty + cursorPenalty
    }

    private func constrainedFrame(_ frame: CGRect, within visibleFrame: CGRect) -> CGRect {
        let constrainedX = min(max(frame.minX, visibleFrame.minX + auxiliaryPanelMargin), visibleFrame.maxX - frame.width - auxiliaryPanelMargin)
        let constrainedY = min(max(frame.minY, visibleFrame.minY + auxiliaryPanelMargin), visibleFrame.maxY - frame.height - auxiliaryPanelMargin)

        return CGRect(x: constrainedX, y: constrainedY, width: frame.width, height: frame.height)
    }

    func applyBrowseFrame(to window: NSWindow) {
        setFrameIfNeeded(browseFrame(), to: window)
    }

    func applyTheaterFrame(to window: NSWindow) {
        setFrameIfNeeded(theaterFrame(), to: window)
    }

    func applyFullscreenOverlayFrame(to window: NSWindow) {
        setFrameIfNeeded(fullscreenOverlayFrame(), to: window)
    }

    func applyImagePanelFrame(to window: NSWindow) {
        setFrameIfNeeded(imagePanelFrame(), to: window)
    }

    func applyImagePanelFrame(_ frame: CGRect, to window: NSWindow) {
        setFrameIfNeeded(frame, to: window)
    }

    private func setFrameIfNeeded(_ frame: CGRect, to window: NSWindow) {
        guard !window.frame.integral.equalTo(frame.integral) else {
            return
        }

        window.setFrame(frame, display: true, animate: false)
    }
}

private extension CGRect {
    var area: CGFloat {
        max(width, 0) * max(height, 0)
    }

    func withSize(_ size: CGSize) -> CGRect {
        CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
}
