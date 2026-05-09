import AppKit

@MainActor
struct OverlayLayoutService {
    private let browseWidthRatio: CGFloat = 0.30
    private let theaterWidthRatio: CGFloat = 0.32
    private let browseAspectRatio: CGFloat = 16.0 / 10.0
    private let theaterAspectRatio: CGFloat = 16.0 / 9.0
    private let horizontalMarginRatio: CGFloat = 0.03
    private let verticalMarginRatio: CGFloat = 0.03

    func browseFrame() -> CGRect {
        frame(forWidthRatio: browseWidthRatio, aspectRatio: browseAspectRatio)
    }

    func theaterFrame() -> CGRect {
        frame(forWidthRatio: theaterWidthRatio, aspectRatio: theaterAspectRatio)
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

    func applyBrowseFrame(to window: NSWindow) {
        setFrameIfNeeded(browseFrame(), to: window)
    }

    func applyTheaterFrame(to window: NSWindow) {
        setFrameIfNeeded(theaterFrame(), to: window)
    }

    func applyFullscreenOverlayFrame(to window: NSWindow) {
        setFrameIfNeeded(fullscreenOverlayFrame(), to: window)
    }

    private func setFrameIfNeeded(_ frame: CGRect, to window: NSWindow) {
        guard !window.frame.integral.equalTo(frame.integral) else {
            return
        }

        window.setFrame(frame, display: true, animate: false)
    }
}
