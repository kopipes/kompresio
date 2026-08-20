import AppKit

// Enforce single instance — terminate any existing Kompresio process
let bundleID = "com.bob.kompresio"
let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
for app in running {
    if app != NSRunningApplication.current {
        app.terminate()
    }
}

autoreleasepool {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
