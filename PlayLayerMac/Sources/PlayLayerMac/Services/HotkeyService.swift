import Carbon
import Foundation

final class HotkeyService {
    private struct Registration {
        let id: UInt32
        let ref: EventHotKeyRef?
    }

    private enum HotkeyID: UInt32 {
        case toggleTheaterMode = 1
        case returnToHome = 2
        case toggleOverlayVisibility = 3
        case showGuide = 4
        case togglePlayback = 5
        case seekBackward = 6
        case seekForward = 7
        case openSampleImagePanel = 8
        case captureAreaToPanel = 9
        case showCommandBar = 10
        case showCommandBarAlternate = 11
    }

    private var registrations: [Registration] = []
    private var eventHandler: EventHandlerRef?
    private var handlers: [UInt32: () -> Void] = [:]

    func registerDefaultHotkeys(
        toggleTheaterModeHandler: @escaping () -> Void,
        returnToHomeHandler: @escaping () -> Void,
        toggleOverlayVisibilityHandler: @escaping () -> Void,
        showGuideHandler: @escaping () -> Void,
        togglePlaybackHandler: @escaping () -> Void,
        seekBackwardHandler: @escaping () -> Void,
        seekForwardHandler: @escaping () -> Void,
        openSampleImagePanelHandler: @escaping () -> Void,
        captureAreaToPanelHandler: @escaping () -> Void,
        showCommandBarHandler: @escaping () -> Void
    ) {
        unregisterAllHotkeys()
        installEventHandlerIfNeeded()

        handlers[HotkeyID.toggleTheaterMode.rawValue] = toggleTheaterModeHandler
        handlers[HotkeyID.returnToHome.rawValue] = returnToHomeHandler
        handlers[HotkeyID.toggleOverlayVisibility.rawValue] = toggleOverlayVisibilityHandler
        handlers[HotkeyID.showGuide.rawValue] = showGuideHandler
        handlers[HotkeyID.togglePlayback.rawValue] = togglePlaybackHandler
        handlers[HotkeyID.seekBackward.rawValue] = seekBackwardHandler
        handlers[HotkeyID.seekForward.rawValue] = seekForwardHandler
        handlers[HotkeyID.openSampleImagePanel.rawValue] = openSampleImagePanelHandler
        handlers[HotkeyID.captureAreaToPanel.rawValue] = captureAreaToPanelHandler
        handlers[HotkeyID.showCommandBar.rawValue] = showCommandBarHandler
        handlers[HotkeyID.showCommandBarAlternate.rawValue] = showCommandBarHandler
        registerHotKey(
            id: .toggleTheaterMode,
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .returnToHome,
            keyCode: UInt32(kVK_ANSI_H),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .toggleOverlayVisibility,
            keyCode: UInt32(kVK_ANSI_O),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .showGuide,
            keyCode: UInt32(kVK_ANSI_C),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .togglePlayback,
            keyCode: UInt32(kVK_ANSI_P),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .seekBackward,
            keyCode: UInt32(kVK_LeftArrow),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .seekForward,
            keyCode: UInt32(kVK_RightArrow),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .openSampleImagePanel,
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .captureAreaToPanel,
            keyCode: UInt32(kVK_ANSI_2),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .showCommandBar,
            keyCode: UInt32(kVK_Space),
            modifiers: UInt32(controlKey | optionKey)
        )
        registerHotKey(
            id: .showCommandBarAlternate,
            keyCode: UInt32(kVK_ANSI_L),
            modifiers: UInt32(controlKey | optionKey)
        )
    }

    func unregisterAllHotkeys() {
        registrations.forEach { registration in
            if let ref = registration.ref {
                UnregisterEventHotKey(ref)
            }
        }
        registrations.removeAll()
        handlers.removeAll()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard
                    let userData,
                    let eventRef
                else {
                    return OSStatus(eventNotHandledErr)
                }

                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                return service.handleHotkeyEvent(eventRef)
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        if status != noErr {
            eventHandler = nil
        }
    }

    private func registerHotKey(id: HotkeyID, keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: fourCharCode(from: "PLYR"), id: id.rawValue)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            registrations.append(Registration(id: id.rawValue, ref: hotKeyRef))
        } else {
            print("[Lumi][Hotkeys] Failed to register hotkey id \(id.rawValue) status \(status)")
        }
    }

    private func handleHotkeyEvent(_ eventRef: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return status
        }

        handlers[hotKeyID.id]?()
        return noErr
    }

    private func fourCharCode(from value: String) -> OSType {
        value.utf8.reduce(0) { partialResult, byte in
            (partialResult << 8) + OSType(byte)
        }
    }
}
