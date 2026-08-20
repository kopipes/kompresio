import AppKit

// Entry point: keep this nonisolated — AppDelegate picks up on main thread via NSApplicationDelegate
autoreleasepool {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
