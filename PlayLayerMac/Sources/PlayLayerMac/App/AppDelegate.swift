import AppKit
import CoreGraphics
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private struct HiddenPanelSnapshot {
        let imagePanelIDs: Set<UUID>
        let pdfPanelIDs: Set<UUID>
        let commandBarVisible: Bool
    }

    private let launchGuardService = LaunchGuardService()
    private let configService = ConfigService()
    private let hotkeyService = HotkeyService()
    private let panelLayoutService = PanelLayoutService()
    private lazy var trayService = TrayService(
        toggleOverlayHandler: { [weak self] in self?.toggleOverlay() },
        returnToHomeHandler: { [weak self] in self?.returnToHome() },
        showGuideHandler: { [weak self] in self?.showGuide() },
        captureAreaToPanelHandler: { [weak self] in self?.captureAreaToPanel() },
        captureScreenToPanelHandler: { [weak self] in self?.captureScreenToPanel() },
        openImagePanelHandler: { [weak self] in self?.openImagePanel() },
        openPDFPanelHandler: { [weak self] in self?.openPDFPanel() },
        openSampleImagePanelHandler: { [weak self] in self?.openSampleImagePanel() },
        enablePassModeHandler: { [weak self] in self?.setPassMode() },
        enableInteractModeHandler: { [weak self] in self?.setInteractMode() },
        quitHandler: { NSApplication.shared.terminate(nil) }
    )
    private var panelWindowController: PanelWindowController?
    private let commandBarWindowController = CommandBarWindowController()
    private var imagePanelWindowControllers: [UUID: ImagePanelWindowController] = [:]
    private var pdfPanelWindowControllers: [UUID: PDFPanelWindowController] = [:]
    private var areaSelectionWindowController: AreaSelectionWindowController?
    private var hiddenPanelSnapshot: HiddenPanelSnapshot?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = notification
        applyApplicationBranding()

        if !launchGuardService.acquire() {
            let reason = launchGuardService.lastFailureReason ?? "unknown launch guard failure"
            print("[Lumi][Launch] Continuing without launch socket lock: \(reason)")
        }

        var config = configService.load()
        config.overlayFullscreenEnabled = false
        config.interactModeEnabled = true
        configService.save(config)
        panelWindowController = PanelWindowController(config: config, configService: configService)
        trayService.install()
        hotkeyService.registerDefaultHotkeys(
            toggleTheaterModeHandler: { [weak self] in
                self?.panelWindowController?.toggleTheaterMode()
            },
            returnToHomeHandler: { [weak self] in
                self?.panelWindowController?.returnToHome()
            },
            toggleOverlayVisibilityHandler: { [weak self] in
                self?.toggleOverlay()
            },
            showGuideHandler: { [weak self] in
                self?.panelWindowController?.showGuide()
            },
            togglePlaybackHandler: { [weak self] in
                self?.panelWindowController?.togglePlayback()
            },
            seekBackwardHandler: { [weak self] in
                self?.panelWindowController?.seekBackward()
            },
            seekForwardHandler: { [weak self] in
                self?.panelWindowController?.seekForward()
            },
            openSampleImagePanelHandler: { [weak self] in
                self?.openSampleImagePanel()
            },
            captureAreaToPanelHandler: { [weak self] in
                self?.captureAreaToPanel()
            },
            showCommandBarHandler: { [weak self] in
                self?.showCommandBar()
            }
        )

        presentInitialWindows()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        _ = sender
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        _ = sender

        guard !flag else { return false }

        if hiddenPanelSnapshot != nil {
            restoreVisibleSurfacesIfNeeded()
        } else {
            showCommandBar(asHomeSurface: true)
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        _ = notification
        saveWorkspaceSession()
        hotkeyService.unregisterAllHotkeys()
        panelWindowController?.stopObservingSpaces()
    }

    private func showOverlay() {
        panelWindowController?.showOverlay()
    }

    private func presentInitialWindows() {
        showCommandBar(asHomeSurface: true)
    }

    private func applyApplicationBranding() {
        guard
            let orbURL = Bundle.module.url(forResource: "LumiOrb", withExtension: "png"),
            let orbImage = NSImage(contentsOf: orbURL)
        else {
            return
        }

        NSApplication.shared.applicationIconImage = orbImage
    }

    private func hideOverlay() {
        panelWindowController?.hideOverlay()
    }

    private func toggleOverlay() {
        guard let panelWindowController else { return }

        if panelWindowController.isOverlayVisible {
            hiddenPanelSnapshot = HiddenPanelSnapshot(
                imagePanelIDs: Set(imagePanelWindowControllers.compactMap { $0.value.isPanelVisible ? $0.key : nil }),
                pdfPanelIDs: Set(pdfPanelWindowControllers.compactMap { $0.value.isPanelVisible ? $0.key : nil }),
                commandBarVisible: commandBarWindowController.isCommandBarVisible
            )

            imagePanelWindowControllers.values.forEach { $0.hidePanel() }
            pdfPanelWindowControllers.values.forEach { $0.hidePanel() }
            if commandBarWindowController.isCommandBarVisible {
                commandBarWindowController.hideCommandBar()
            }
            panelWindowController.hideOverlay()
        } else {
            restoreVisibleSurfacesIfNeeded()
        }
    }

    private func restoreVisibleSurfacesIfNeeded() {
        guard let panelWindowController else { return }

        panelWindowController.showOverlay(showFeedback: false)

        guard let hiddenPanelSnapshot else { return }

        for panelID in hiddenPanelSnapshot.imagePanelIDs {
            imagePanelWindowControllers[panelID]?.showPanel()
        }

        for panelID in hiddenPanelSnapshot.pdfPanelIDs {
            pdfPanelWindowControllers[panelID]?.showPanel()
        }

        if hiddenPanelSnapshot.commandBarVisible {
            commandBarWindowController.showCommandBar(actions: commandBarActions())
        }

        self.hiddenPanelSnapshot = nil
    }

    private func returnToHome() {
        panelWindowController?.returnToHome()
    }

    private func showGuide() {
        panelWindowController?.showGuide()
    }

    private func showCommandBar() {
        print("[Lumi][CommandBar] Opening command bar")
        commandBarWindowController.showCommandBar(actions: commandBarActions())
    }

    private func showCommandBar(asHomeSurface: Bool) {
        print("[Lumi][CommandBar] Opening command bar")
        commandBarWindowController.showCommandBar(actions: commandBarActions(), asHomeSurface: asHomeSurface)
    }

    private func openSampleImagePanel() {
        openImagePanel(
            with: ImagePanelWindowController.makePlaceholderImage(),
            spawnIntent: .genericImage,
            sourceURL: nil,
            feedbackIcon: "photo.fill",
            feedbackTitle: "Sample Image",
            logMessage: "[Lumi][ImagePanel] Opened sample pinned image panel"
        )
    }

    private func openImagePanel() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.png, .jpeg, .heic]
        openPanel.prompt = "Open Image"
        openPanel.title = "Open Image Panel"

        guard openPanel.runModal() == .OK, let selectedURL = openPanel.url else {
            print("[Lumi][ImagePanel] Open image cancelled")
            return
        }

        guard let image = NSImage(contentsOf: selectedURL) else {
            print("[Lumi][ImagePanel] Failed to load image at path: \(selectedURL.path)")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Image Load Failed")
            return
        }

        openImagePanel(
            with: image,
            spawnIntent: .genericImage,
            sourceURL: selectedURL,
            feedbackIcon: "photo.fill",
            feedbackTitle: "Image Panel",
            logMessage: "[Lumi][ImagePanel] Opened image panel for path: \(selectedURL.lastPathComponent)"
        )
    }

    private func openPDFPanel() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.pdf]
        openPanel.prompt = "Open PDF"
        openPanel.title = "Open PDF Panel"

        guard openPanel.runModal() == .OK, let selectedURL = openPanel.url else {
            print("[Lumi][PDFPanel] Open PDF cancelled")
            return
        }

        guard let document = PDFDocument(url: selectedURL) else {
            print("[Lumi][PDFPanel] Failed to load PDF at path: \(selectedURL.path)")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "PDF Load Failed")
            return
        }

        openPDFPanel(
            with: document,
            sourceURL: selectedURL,
            feedbackIcon: "doc.richtext.fill",
            feedbackTitle: "PDF Panel",
            logMessage: "[Lumi][PDFPanel] Opened PDF panel for path: \(selectedURL.lastPathComponent)"
        )
    }

    private func captureScreenToPanel() {
        guard CGPreflightScreenCaptureAccess() else {
            print("[Lumi][Capture] Screen capture permission not granted")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Screen Capture Blocked")
            return
        }

        guard let capture = CGDisplayCreateImage(CGMainDisplayID()) else {
            print("[Lumi][Capture] Failed to capture main display image")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Capture Failed")
            return
        }

        let imageSize = NSSize(width: capture.width, height: capture.height)
        let image = NSImage(cgImage: capture, size: imageSize)
        openImagePanel(
            with: image,
            spawnIntent: .screenshot,
            sourceURL: nil,
            focusArea: panelWindowController?.currentFrame,
            feedbackIcon: "camera.fill",
            feedbackTitle: "Screen Panel",
            logMessage: "[Lumi][Capture] Opened screen capture panel"
        )
    }

    private func captureAreaToPanel() {
        guard CGPreflightScreenCaptureAccess() else {
            print("[Lumi][Capture] Screen capture permission not granted for area selection")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Screen Capture Blocked")
            return
        }

        guard areaSelectionWindowController == nil else {
            print("[Lumi][Capture] Area selection already active")
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let selectionScreen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main

        guard let selectionScreen else {
            print("[Lumi][Capture] No screen available for area selection")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Capture Failed")
            return
        }

        let controller = AreaSelectionWindowController(screen: selectionScreen) { [weak self] selectedRect in
            guard let self else { return }
            self.areaSelectionWindowController = nil

            guard let selectedRect else {
                print("[Lumi][Capture] Area selection cancelled")
                return
            }

            self.captureAreaRectToPanel(selectedRect, on: selectionScreen)
        }

        areaSelectionWindowController = controller
        print("[Lumi][Capture] Started area selection on screen \(selectionScreen.frame.debugDescription)")
        panelWindowController?.showActionFeedback(icon: "selection.pin.in.out", title: "Select Area")
        controller.showSelectionOverlay()
    }

    private func openImagePanel(
        with image: NSImage,
        spawnIntent: PanelLayoutService.AuxiliaryPanelSpawnIntent,
        sourceURL: URL?,
        focusArea: CGRect? = nil,
        initialFrame: CGRect? = nil,
        feedbackIcon: String,
        feedbackTitle: String,
        logMessage: String
    ) {
        let config = configService.load()
        let panelID = UUID()
        let resolvedInitialFrame = initialFrame ?? panelLayoutService.nextAuxiliaryPanelFrame(
            size: panelLayoutService.imagePanelSpawnSize(for: image),
            intent: spawnIntent,
            avoiding: visiblePanelFrames(),
            focusArea: focusArea,
            cursorLocation: NSEvent.mouseLocation
        )
        let controller = ImagePanelWindowController(
            opacity: config.opacity,
            isInteractive: config.interactModeEnabled,
            image: image,
            sourceURL: sourceURL,
            initialFrame: resolvedInitialFrame
        ) { [weak self] in
            self?.imagePanelWindowControllers.removeValue(forKey: panelID)
            self?.saveWorkspaceSession()
        }

        imagePanelWindowControllers[panelID] = controller
        controller.showPanel()
        print("\(logMessage) \(panelID.uuidString)")
        panelWindowController?.showActionFeedback(icon: feedbackIcon, title: feedbackTitle)
        saveWorkspaceSession()
    }

    private func openPDFPanel(
        with document: PDFDocument,
        sourceURL: URL?,
        initialFrame: CGRect? = nil,
        feedbackIcon: String,
        feedbackTitle: String,
        logMessage: String
    ) {
        let config = configService.load()
        let panelID = UUID()
        let resolvedInitialFrame = initialFrame ?? panelLayoutService.nextAuxiliaryPanelFrame(
            size: panelLayoutService.pdfPanelSpawnSize(),
            intent: .pdf,
            avoiding: visiblePanelFrames(),
            cursorLocation: NSEvent.mouseLocation
        )
        let controller = PDFPanelWindowController(
            opacity: config.opacity,
            isInteractive: config.interactModeEnabled,
            document: document,
            sourceURL: sourceURL,
            initialFrame: resolvedInitialFrame
        ) { [weak self] in
            self?.pdfPanelWindowControllers.removeValue(forKey: panelID)
            self?.saveWorkspaceSession()
        }

        pdfPanelWindowControllers[panelID] = controller
        controller.showPanel()
        print("\(logMessage) \(panelID.uuidString)")
        panelWindowController?.showActionFeedback(icon: feedbackIcon, title: feedbackTitle)
        saveWorkspaceSession()
    }

    private func captureAreaRectToPanel(_ selectedRect: CGRect, on screen: NSScreen) {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            print("[Lumi][Capture] Missing screen number for area selection capture")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Capture Failed")
            return
        }

        let displayID = CGDirectDisplayID(screenNumber.uint32Value)
        guard let fullCapture = CGDisplayCreateImage(displayID) else {
            print("[Lumi][Capture] Failed to capture source display image for area selection")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Capture Failed")
            return
        }

        let screenFrame = screen.frame
        let localRect = CGRect(
            x: selectedRect.minX - screenFrame.minX,
            y: selectedRect.minY - screenFrame.minY,
            width: selectedRect.width,
            height: selectedRect.height
        )

        let scaleX = CGFloat(fullCapture.width) / screenFrame.width
        let scaleY = CGFloat(fullCapture.height) / screenFrame.height
        let cropRect = CGRect(
            x: localRect.minX * scaleX,
            y: (screenFrame.height - localRect.maxY) * scaleY,
            width: localRect.width * scaleX,
            height: localRect.height * scaleY
        ).integral

        guard let croppedCapture = fullCapture.cropping(to: cropRect) else {
            print("[Lumi][Capture] Failed to crop selected area \(cropRect.debugDescription)")
            panelWindowController?.showActionFeedback(icon: "exclamationmark.triangle.fill", title: "Capture Failed")
            return
        }

        let image = NSImage(cgImage: croppedCapture, size: selectedRect.size)
        openImagePanel(
            with: image,
            spawnIntent: .screenshot,
            sourceURL: nil,
            focusArea: selectedRect,
            initialFrame: panelLayoutService.constrainedAuxiliaryFrame(selectedRect),
            feedbackIcon: "selection.pin.in.out",
            feedbackTitle: "Area Panel",
            logMessage: "[Lumi][Capture] Opened area capture panel"
        )
    }

    private func setPassMode() {
        panelWindowController?.setInteractMode(false)
        imagePanelWindowControllers.values.forEach { $0.setInteractive(false) }
        pdfPanelWindowControllers.values.forEach { $0.setInteractive(false) }
    }

    private func setInteractMode() {
        panelWindowController?.setInteractMode(true)
        imagePanelWindowControllers.values.forEach { $0.setInteractive(true) }
        pdfPanelWindowControllers.values.forEach { $0.setInteractive(true) }
    }

    private func visiblePanelFrames() -> [CGRect] {
        var frames: [CGRect] = []

        if let frame = panelWindowController?.currentFrame, panelWindowController?.isOverlayVisible == true {
            frames.append(frame)
        }

        frames.append(contentsOf: imagePanelWindowControllers.values.compactMap { $0.isPanelVisible ? $0.currentFrame : nil })
        frames.append(contentsOf: pdfPanelWindowControllers.values.compactMap { $0.isPanelVisible ? $0.currentFrame : nil })

        if commandBarWindowController.isCommandBarVisible, let frame = commandBarWindowController.currentFrame {
            frames.append(frame)
        }

        return frames
    }

    private func saveWorkspaceSession() {
        guard let panelWindowController else { return }

        var config = configService.load()
        config.panelHomeURL = panelWindowController.currentURLString

        let webPanelSession = RestorableWebPanelSession(
            url: panelWindowController.currentURLString,
            frame: PanelFrameRecord(frame: panelWindowController.currentFrame ?? panelLayoutService.browseFrame()),
            opacity: config.opacity
        )

        let imagePanels = imagePanelWindowControllers.values.compactMap { controller -> RestorableFilePanelSession? in
            guard
                let sourceURL = controller.sourceURL,
                let frame = controller.currentFrame,
                controller.isPanelVisible
            else {
                return nil
            }

            return RestorableFilePanelSession(
                path: sourceURL.path,
                frame: PanelFrameRecord(frame: frame),
                opacity: config.opacity
            )
        }

        let pdfPanels = pdfPanelWindowControllers.values.compactMap { controller -> RestorableFilePanelSession? in
            guard
                let sourceURL = controller.sourceURL,
                let frame = controller.currentFrame,
                controller.isPanelVisible
            else {
                return nil
            }

            return RestorableFilePanelSession(
                path: sourceURL.path,
                frame: PanelFrameRecord(frame: frame),
                opacity: config.opacity
            )
        }

        config.workspaceSession = WorkspaceSession(
            webPanel: webPanelSession,
            imagePanels: imagePanels,
            pdfPanels: pdfPanels
        )
        configService.save(config)
    }

    private func restoreWorkspacePanels(from session: WorkspaceSession?) {
        guard let session else { return }

        for imagePanel in session.imagePanels {
            let fileURL = URL(fileURLWithPath: imagePanel.path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("[Lumi][Workspace] Skipping missing image panel file: \(fileURL.path)")
                continue
            }

            guard let image = NSImage(contentsOf: fileURL) else {
                print("[Lumi][Workspace] Failed to restore image panel from path: \(fileURL.path)")
                continue
            }

            openImagePanel(
                with: image,
                spawnIntent: .genericImage,
                sourceURL: fileURL,
                focusArea: nil,
                initialFrame: panelLayoutService.constrainedAuxiliaryFrame(imagePanel.frame.cgRect),
                feedbackIcon: "photo.fill",
                feedbackTitle: "Image Panel",
                logMessage: "[Lumi][Workspace] Restored image panel: \(fileURL.lastPathComponent)"
            )
        }

        for pdfPanel in session.pdfPanels {
            let fileURL = URL(fileURLWithPath: pdfPanel.path)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("[Lumi][Workspace] Skipping missing PDF panel file: \(fileURL.path)")
                continue
            }

            guard let document = PDFDocument(url: fileURL) else {
                print("[Lumi][Workspace] Failed to restore PDF panel from path: \(fileURL.path)")
                continue
            }

            openPDFPanel(
                with: document,
                sourceURL: fileURL,
                initialFrame: panelLayoutService.constrainedAuxiliaryFrame(pdfPanel.frame.cgRect),
                feedbackIcon: "doc.richtext.fill",
                feedbackTitle: "PDF Panel",
                logMessage: "[Lumi][Workspace] Restored PDF panel: \(fileURL.lastPathComponent)"
            )
        }
    }

    private func commandBarActions() -> [CommandBarAction] {
        [
            CommandBarAction(
                title: "Open YouTube Overlay",
                keywords: ["youtube", "overlay", "web", "show"],
                shortcutHint: "Ctrl Opt O"
            ) { [weak self] in
                self?.showOverlay()
            },
            CommandBarAction(
                title: "Open Image Panel...",
                keywords: ["image", "photo", "png", "jpg"],
                shortcutHint: nil
            ) { [weak self] in
                self?.openImagePanel()
            },
            CommandBarAction(
                title: "Open PDF Panel...",
                keywords: ["pdf", "document", "file"],
                shortcutHint: nil
            ) { [weak self] in
                self?.openPDFPanel()
            },
            CommandBarAction(
                title: "Capture Screen to Panel",
                keywords: ["capture", "screen", "screenshot", "full"],
                shortcutHint: nil
            ) { [weak self] in
                self?.captureScreenToPanel()
            },
            CommandBarAction(
                title: "Capture Area to Panel",
                keywords: ["capture", "area", "selection", "crop"],
                shortcutHint: "Ctrl Opt 2"
            ) { [weak self] in
                self?.captureAreaToPanel()
            },
            CommandBarAction(
                title: "Show Keyboard Shortcuts",
                keywords: ["help", "shortcuts", "keys", "guide"],
                shortcutHint: "Ctrl Opt C"
            ) { [weak self] in
                self?.showGuide()
            },
            CommandBarAction(
                title: "Quit Lumi",
                keywords: ["quit", "exit", "close app"],
                shortcutHint: "Cmd Q"
            ) {
                NSApplication.shared.terminate(nil)
            },
        ]
    }
}
