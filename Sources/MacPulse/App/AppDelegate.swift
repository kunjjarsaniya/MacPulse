import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as seamless accessory (Menu Bar + Floating Dynamic Island only)
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        
        // Show exclusively the intelligent floating Dynamic Island
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            DynamicIslandController.shared.show()
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: "MacPulse")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 280, height: 260)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView {
                DynamicIslandController.shared.toggle()
            }
        )
        self.popover = pop
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        DynamicIslandController.shared.show()
        return true
    }
}
