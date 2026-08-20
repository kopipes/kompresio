import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var contentViewModel = ContentViewModel()

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.down.circle.fill",
                                   accessibilityDescription: "Kompresio")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            // Register for drag & drop on the status bar button
            button.registerForDraggedTypes([.fileURL])
            // We'll use a custom drag view wrapper instead
        }

        setupDragOverlay()
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 460)
        popover.behavior = .applicationDefined
        popover.animates = true

        let contentView = ContentView(viewModel: contentViewModel, onClose: { [weak self] in
            self?.popover.performClose(nil)
        })
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    // MARK: - Drag support on status button

    private func setupDragOverlay() {
        // Attach a drag-destination view on top of the status button
        guard let button = statusItem.button,
              let window = button.window else {
            // Window may not exist yet — retry after a tick
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupDragOverlay()
            }
            return
        }
        let dragView = DragReceivingView(frame: button.bounds)
        dragView.onDrop = { [weak self] urls in
            self?.handleDroppedURLs(urls)
        }
        dragView.autoresizingMask = [.width, .height]
        button.addSubview(dragView)
        _ = window // silence warning
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        let event = NSApp.currentEvent
        // Right-click → show context menu with Quit
        if event?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Kompresio v1.0", action: nil, keyEquivalent: ""))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            // Remove menu after use so left-click still works
            DispatchQueue.main.async { self.statusItem.menu = nil }
            return
        }
        // Left-click → toggle popover
        if popover.isShown {
            popover.performClose(nil)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func handleDroppedURLs(_ urls: [URL]) {
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return }

        // Show popover so user can see progress
        if !popover.isShown, let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        contentViewModel.processURLs(imageURLs)
    }
}

// MARK: - DragReceivingView

final class DragReceivingView: NSView {
    var onDrop: (([URL]) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let hasImages = sender.draggingPasteboard
            .readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?
            .compactMap({ $0 as? URL })
            .contains(where: { $0.isImageFile }) ?? false
        return hasImages ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard
            .readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?
            .compactMap({ $0 as? URL }) else { return false }
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return false }
        onDrop?(imageURLs)
        return true
    }
}

// MARK: - URL helper

extension URL {
    var isImageFile: Bool {
        let imageExtensions = ["jpg","jpeg","png","gif","tiff","tif","bmp","webp","heic","heif"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
}
