import AppKit

@MainActor
enum PanelSnapService {
    private static let snapThreshold: CGFloat = 12
    private static let edgeInset: CGFloat = 6

    static func adjustedFrame(for frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let constrainedFrame = constrainedFrame(for: frame, in: visibleFrame)
        let snappedX = snappedHorizontalOrigin(for: constrainedFrame, in: visibleFrame)
        let snappedY = snappedVerticalOrigin(for: constrainedFrame, in: visibleFrame)

        return CGRect(x: snappedX, y: snappedY, width: constrainedFrame.width, height: constrainedFrame.height)
    }

    private static func snappedHorizontalOrigin(for frame: CGRect, in visibleFrame: CGRect) -> CGFloat {
        let leftDistance = frame.minX - visibleFrame.minX
        let rightDistance = visibleFrame.maxX - frame.maxX
        let snappedRightOrigin = visibleFrame.maxX - frame.width

        if leftDistance <= snapThreshold {
            return visibleFrame.minX
        }

        if rightDistance <= snapThreshold {
            return snappedRightOrigin
        }

        return frame.origin.x
    }

    private static func snappedVerticalOrigin(for frame: CGRect, in visibleFrame: CGRect) -> CGFloat {
        let bottomDistance = frame.minY - visibleFrame.minY
        let topDistance = visibleFrame.maxY - frame.maxY
        let snappedTopOrigin = visibleFrame.maxY - frame.height

        if topDistance <= snapThreshold {
            return snappedTopOrigin
        }

        if bottomDistance <= snapThreshold {
            return visibleFrame.minY
        }

        return frame.origin.y
    }

    private static func constrainedFrame(for frame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let minX = visibleFrame.minX - edgeInset
        let maxX = visibleFrame.maxX - frame.width + edgeInset
        let minY = visibleFrame.minY - edgeInset
        let maxY = visibleFrame.maxY - frame.height + edgeInset

        let x = min(max(frame.origin.x, minX), maxX)
        let y = min(max(frame.origin.y, minY), maxY)
        return CGRect(x: x, y: y, width: frame.width, height: frame.height)
    }
}
