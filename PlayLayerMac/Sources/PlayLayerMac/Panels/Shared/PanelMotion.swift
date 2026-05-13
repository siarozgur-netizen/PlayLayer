import AppKit
import QuartzCore

@MainActor
enum PanelMotion {
    static func animateIn(_ window: NSWindow) {
        let targetFrame = window.frame
        let startFrame = scaledFrame(for: targetFrame, scale: 0.975)

        window.alphaValue = 0
        window.setFrame(startFrame, display: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(targetFrame, display: true)
        }
    }

    static func animateOut(_ window: NSWindow, completion: @MainActor @escaping () -> Void) {
        let startFrame = window.frame

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.09
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                completion()
                window.alphaValue = 1
                window.setFrame(startFrame, display: false)
            }
        })
    }

    static func animateCommandBarIn(_ window: NSWindow) {
        let targetFrame = window.frame
        let startFrame = scaledFrame(for: targetFrame, scale: 0.985)

        window.alphaValue = 0
        window.setFrame(startFrame, display: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(targetFrame, display: true)
        }
    }

    static func animateCommandBarOut(_ window: NSWindow, completion: @MainActor @escaping () -> Void) {
        let startFrame = window.frame

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor in
                completion()
                window.alphaValue = 1
                window.setFrame(startFrame, display: false)
            }
        })
    }

    private static func scaledFrame(for frame: CGRect, scale: CGFloat) -> CGRect {
        let width = frame.width * scale
        let height = frame.height * scale
        let x = frame.midX - (width / 2)
        let y = frame.midY - (height / 2)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
