import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
    }

    // Accept files dropped onto the Dock icon (won't show but handles open events)
    func application(_ sender: NSApplication, open urls: [URL]) {
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return }
        statusBarController?.handleDroppedURLs(imageURLs)
    }
}
