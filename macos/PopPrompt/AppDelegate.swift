import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let store = PromptStore()

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var eventMonitor: Any?
    private var globalEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configurePopover()
        configureStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        popover.performClose(nil)
        stopEventMonitors()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 430, height: 560)
        refreshPopoverContent()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        guard let button = item.button else { return }

        button.image = NSImage(named: "StatusIcon") ?? NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "PopPrompt")
        button.image?.isTemplate = true
        button.action = #selector(handleStatusItemClick(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.toolTip = "PopPrompt"
    }

    private func refreshPopoverContent() {
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(store)
        )
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        switch NSApp.currentEvent?.type {
        case .rightMouseUp:
            showContextMenu()
        default:
            togglePopover(relativeTo: sender)
        }
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(nil)
            stopEventMonitors()
        } else {
            refreshPopoverContent()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.becomeKey()
            startEventMonitors()
        }
    }

    private func showContextMenu() {
        popover.performClose(nil)
        stopEventMonitors()

        let menu = NSMenu()
        menu.delegate = self
        let quitItem = menu.addItem(
            withTitle: "Quit PopPrompt",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem?.menu = nil
    }

    private func startEventMonitors() {
        stopEventMonitors()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closePopoverIfNeeded(for: event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.closePopoverIfNeeded(for: event)
            }
        }
    }

    private func stopEventMonitors() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    private func closePopoverIfNeeded(for event: NSEvent) {
        guard popover.isShown else { return }
        guard let popoverWindow = popover.contentViewController?.view.window else { return }

        if let eventWindow = event.window {
            if isPopoverRelatedWindow(eventWindow, popoverWindow: popoverWindow) {
                return
            }
        } else {
            // Global events often arrive without a window reference; treat them as outside clicks.
        }

        popover.performClose(nil)
        stopEventMonitors()
    }

    private func isPopoverRelatedWindow(_ window: NSWindow, popoverWindow: NSWindow) -> Bool {
        if window === popoverWindow || window === statusItem?.button?.window {
            return true
        }

        var currentWindow: NSWindow? = window
        while let candidate = currentWindow {
            if candidate === popoverWindow || candidate === statusItem?.button?.window {
                return true
            }

            if candidate.parent === popoverWindow || candidate.sheetParent === popoverWindow {
                return true
            }

            currentWindow = candidate.parent ?? candidate.sheetParent
        }

        return false
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
