import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
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
        guard let button = statusItem.button,
              let _ = button.window else {
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
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showContextMenu()
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

    private func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let title = NSMenuItem(title: "Kompresio v1.0", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Kompresio", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        // Temporarily assign menu so system can display it
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }

    // NSMenuDelegate — clear menu after it closes so left-click still triggers our action
    nonisolated func menuDidClose(_ menu: NSMenu) {
        Task { @MainActor in
            self.statusItem.menu = nil
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func handleDroppedURLs(_ urls: [URL]) {
        let imageURLs = urls.filter { $0.isImageFile }
        guard !imageURLs.isEmpty else { return }

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
