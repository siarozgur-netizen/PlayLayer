import AppKit
import SwiftUI

struct ImagePanelView: View {
    let image: NSImage
    let isActive: Bool
    let copyHandler: () -> Void
    let saveHandler: () -> Void
    let closeHandler: () -> Void
    @State private var isHovered = false
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .top) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .integratedPanelContent(
                    fillColor: PremiumPanelStyle.contentBedColor,
                    cornerSofteningOpacity: 0,
                    cornerRadius: 16.8,
                    edgeShadowOpacity: 0.055,
                    edgeHighlightOpacity: 0.034
                )

            MinimalPanelHeader(
                leading: {
                    FloatingTrafficLightCloseButton(action: closeHandler)
                },
                center: {
                    HStack(spacing: 8) {
                        FloatingPanelIconButton(icon: "doc.on.doc", action: copyHandler)
                        FloatingPanelIconButton(icon: "square.and.arrow.down", action: saveHandler)
                        PanelGripDots()
                    }
                },
                isDragging: $isDragging,
                isActive: isActive,
                isHovered: isHovered
            )
        }
        .background(PremiumPanelStyle.contentBedColor)
        .premiumPanelChrome(isActive: isActive, isHovered: isHovered, isDragging: isDragging)
        .onHover { isHovered = $0 }
    }
}
