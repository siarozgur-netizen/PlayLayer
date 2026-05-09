# PlayLayerMac

Native macOS implementation plan for PlayLayer.

## Target

- `macOS 13+`
- Apple Silicon first
- Minecraft borderless/windowed usage first

## Current Scope

- Borderless always-on-top overlay window
- Tray icon
- Config persistence
- Native macOS project structure for PASS / INTERACT and hotkeys
- `WKWebView` for YouTube

## Milestones

1. Overlay shell
2. PASS / INTERACT
3. WebView + persistence
4. Search / Home / Theater
5. Playback controls
6. Minecraft validation

## Notes

This folder starts as a Swift package scaffold because full Xcode app tooling is not active in the current environment yet. The source layout is intentionally native-first so we can move into an Xcode app target without throwing away the structure.
