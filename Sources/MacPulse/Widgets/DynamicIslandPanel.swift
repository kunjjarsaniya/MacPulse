import AppKit
import SwiftUI

// MARK: - Dynamic Island Panel (Non-activating Top-Level Floating Window)

final class DynamicIslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - FirstMouseHostingView (Instant One-Click Interaction on Floating NSPanel)

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func scrollWheel(with event: NSEvent) {
        if DynamicIslandController.shared.isExpanded && event.scrollingDeltaY > 16 {
            HapticFeedback.playSoft()
            DynamicIslandController.shared.collapse()
            return
        }
        if DynamicIslandController.shared.handleScrollWheelEvent(event) {
            return
        }
        super.scrollWheel(with: event)
    }
}
