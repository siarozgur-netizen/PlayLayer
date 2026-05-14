import AppKit
import PDFKit
import SwiftUI

struct PDFPanelView: View {
    let document: PDFDocument
    let isActive: Bool
    let openInPreviewHandler: () -> Void
    let copyPathHandler: () -> Void
    let closeHandler: () -> Void
    @State private var isHovered = false
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .top) {
            PDFDocumentContainerView(document: document)
                .integratedPanelContent(fillColor: PremiumPanelStyle.contentBedColor)
                .padding(PremiumPanelStyle.contentInset + 1)

            MinimalPanelHeader(
                leading: {
                    FloatingTrafficLightCloseButton(action: closeHandler)
                },
                center: {
                    HStack(spacing: 8) {
                        FloatingPanelIconButton(icon: "eye", action: openInPreviewHandler)
                        FloatingPanelIconButton(icon: "document.on.document", action: copyPathHandler)
                        PanelGripDots()
                    }
                },
                isDragging: $isDragging,
                visible: isHovered || isActive
            )
        }
        .background(PremiumPanelStyle.contentBedColor)
        .premiumPanelChrome(isActive: isActive, isHovered: isHovered, isDragging: isDragging)
        .onHover { isHovered = $0 }
    }
}

private struct PDFDocumentContainerView: NSViewRepresentable {
    let document: PDFDocument

    func makeNSView(context: Context) -> PDFPanelContentNSView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = false
        pdfView.backgroundColor = NSColor(calibratedWhite: 0.08, alpha: 1)
        pdfView.document = document
        return PDFPanelContentNSView(pdfView: pdfView)
    }

    func updateNSView(_ pdfView: PDFPanelContentNSView, context: Context) {
        _ = context
        pdfView.pdfView.document = document
    }
}

@MainActor
private final class PDFPanelContentNSView: NSView {
    let pdfView: PDFView

    init(pdfView: PDFView) {
        self.pdfView = pdfView
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = PremiumPanelStyle.platformContentBedColor.cgColor
        layer?.cornerRadius = PremiumPanelStyle.contentCornerRadius
        layer?.masksToBounds = true
        addSubview(pdfView)
        configureScrollViewIfNeeded()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        pdfView.frame = bounds
        configureScrollViewIfNeeded()
    }

    private func configureScrollViewIfNeeded() {
        guard let scrollView = pdfView.subviews.compactMap({ $0 as? NSScrollView }).first else {
            return
        }

        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.verticalScroller?.alphaValue = 0.55
    }
}
