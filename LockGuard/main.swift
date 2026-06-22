import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// LSUIElement = true means no Dock icon, menu bar only
app.setActivationPolicy(.accessory)
app.run()
