import AppKit

ProcessInfo.processInfo.processName = "Lumi"
let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
