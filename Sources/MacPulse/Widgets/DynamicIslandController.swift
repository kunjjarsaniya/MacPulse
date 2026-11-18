import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Dynamic Island Controller (Window Lifecycle, Distributed Events & Gesture Navigation)

@MainActor
public final class DynamicIslandController: ObservableObject {
    public static let shared = DynamicIslandController()
    
    private var window: DynamicIslandPanel?
    @Published public var isExpanded: Bool = false
    @Published public var activeTab: MacPulseShelfTab = .home
    @Published public var navigationDirection: TabTransitionDirection = .forward
    @Published public var showToast: Bool = false
    @Published public var toastIcon: String = "checkmark.circle.fill"
    @Published public var toastMessage: String = ""
    @Published public var toastSubtitle: String = ""
    private var toastDismissTimer: DispatchWorkItem?
    @Published public var activeLiveActivityText: String? = nil
    @Published public var activeHUD: DynamicIslandHUDType? = nil
    @Published public var showCameraMirror: Bool = false
    @Published public var activeAlert: DynamicIslandAlertItem? = nil
    
    private var alertDismissTimer: DispatchWorkItem?
    private var alertActionHandler: (() -> Void)? = nil
    
    // Gesture-Based Navigation State
    private var accumulatedDeltaX: CGFloat = 0
    private var isSwipeLocked: Bool = false
    private var lastSwipeTimestamp: TimeInterval = 0
    private let swipeThreshold: CGFloat = 16.0
    private let swipeCooldown: TimeInterval = 0.32
    private var localScrollMonitor: Any?
    
    private var liveActivityTimer: DispatchWorkItem?
    private var scrollEventMonitor: Any?
    private var clickOutsideMonitor: Any?
    
    // Apple-Engineered Notch & Island Dimensions
    private let compactSize = MacPulseDimensions.compactIslandSize
    private let expandedSize = MacPulseDimensions.expandedIslandSize
    
    private init() {
        setupDistributedNotifications()
        setupPowerSourceObserver()
        setupScrollMonitor()
    }
    
    private func setupPowerSourceObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.macpulse.powerChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            Task { @MainActor in
                guard let isPlugged = notif.userInfo?["isPluggedIn"] as? Bool,
                      let pct = notif.userInfo?["percentage"] as? Int else { return }
                let msg = isPlugged ? "⚡️ Charging (\(pct)%)" : "Battery Mode (\(pct)%)"
                self?.triggerLiveActivity(msg, duration: 3.5)
            }
        }
    }
    
    public func triggerLiveActivity(_ text: String, duration: TimeInterval = 3.5) {
        liveActivityTimer?.cancel()
        activeLiveActivityText = text
        if !isExpanded {
            updateWindowSize(expanded: false)
        }
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                self.activeLiveActivityText = nil
            }
            if !self.isExpanded {
                self.updateWindowSize(expanded: false)
            }
        }
        liveActivityTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
    
    private func setupScrollMonitor() {
        scrollEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            guard let self = self, let screen = NSScreen.main else { return }
            let mouseLoc = NSEvent.mouseLocation
            
            // If collapsed: pull down gesture near top screen edge expands the island
            if !self.isExpanded {
                guard mouseLoc.y >= (screen.frame.maxY - 45) else { return }
                if event.scrollingDeltaY < -6 {
                    self.expand()
                }
                return
            }
            
            // If expanded: check if cursor is over the dynamic island window for gestures
            if let win = self.window, win.frame.contains(mouseLoc) {
                // Vertical scroll up over dynamic island collapses the shelf
                if event.scrollingDeltaY > 16 {
                    HapticFeedback.playSoft()
                    self.collapse()
                    return
                }
                _ = self.handleScrollWheelEvent(event)
            }
        }
    }
    
    // MARK: - Gesture-Based Tab Navigation Engine
    
    public func selectNextTab() {
        guard isExpanded, activeHUD == nil, !showCameraMirror else { return }
        let all = MacPulseShelfTab.allCases
        guard let currentIdx = all.firstIndex(of: activeTab) else { return }
        if currentIdx < all.count - 1 {
            navigationDirection = .forward
            withAnimation(MacPulseAnimations.dynamicIslandExpand) {
                activeTab = all[currentIdx + 1]
            }
            HapticFeedback.playSoft()
        }
    }
    
    public func selectPreviousTab() {
        guard isExpanded, activeHUD == nil, !showCameraMirror else { return }
        let all = MacPulseShelfTab.allCases
        guard let currentIdx = all.firstIndex(of: activeTab) else { return }
        if currentIdx > 0 {
            navigationDirection = .backward
            withAnimation(MacPulseAnimations.dynamicIslandExpand) {
                activeTab = all[currentIdx - 1]
            }
            HapticFeedback.playSoft()
        }
    }
    
    public func selectTab(_ tab: MacPulseShelfTab) {
        guard activeTab != tab else { return }
        navigationDirection = tab.index > activeTab.index ? .forward : .backward
        withAnimation(MacPulseAnimations.dynamicIslandExpand) {
            activeTab = tab
        }
        HapticFeedback.playSoft()
    }
    
    public func handleScrollWheelEvent(_ event: NSEvent) -> Bool {
        // Only navigate tabs when expanded and not in HUD or mirror mode
        guard isExpanded, activeHUD == nil, !showCameraMirror else { return false }
        
        let now = Date().timeIntervalSince1970
        
        // Reset accumulator and lock when gesture begins, ends, or is cancelled
        if event.phase == .began || event.phase == .ended || event.phase == .cancelled {
            accumulatedDeltaX = 0
            isSwipeLocked = false
            if event.phase == .ended || event.phase == .cancelled {
                return false
            }
        }
        
        // Ignore momentum phase to prevent multiple tab switches from a single flick
        guard event.momentumPhase.isEmpty else {
            return false
        }
        
        // Respect cooldown and lock
        guard !isSwipeLocked, (now - lastSwipeTimestamp) > swipeCooldown else {
            return false
        }
        
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        
        // Vertical scrolling inside views MUST NOT navigate tabs
        guard abs(deltaX) > abs(deltaY) * 1.3 else {
            return false
        }
        
        let all = MacPulseShelfTab.allCases
        
        // For non-precise mouse wheels (e.g. discrete tilt wheel ticks)
        if !event.hasPreciseScrollingDeltas {
            if deltaX < -0.4 {
                lastSwipeTimestamp = now
                isSwipeLocked = true
                if activeTab == all.last {
                    HapticFeedback.playSoft()
                    collapse()
                } else {
                    selectNextTab()
                }
                return true
            } else if deltaX > 0.4 {
                lastSwipeTimestamp = now
                isSwipeLocked = true
                if activeTab == all.first {
                    HapticFeedback.playSoft()
                    collapse()
                } else {
                    selectPreviousTab()
                }
                return true
            }
            return false
        }
        
        // For trackpad precise gestures, accumulate deltaX
        accumulatedDeltaX += deltaX
        
        if accumulatedDeltaX < -swipeThreshold {
            // Swiped Left (fingers move right-to-left) -> Move to Next Tab, or Dismiss at end
            accumulatedDeltaX = 0
            isSwipeLocked = true
            lastSwipeTimestamp = now
            if activeTab == all.last {
                HapticFeedback.playSoft()
                collapse()
            } else {
                selectNextTab()
            }
            return true
        } else if accumulatedDeltaX > swipeThreshold {
            // Swiped Right (fingers move left-to-right) -> Move to Previous Tab, or Dismiss at start
            accumulatedDeltaX = 0
            isSwipeLocked = true
            lastSwipeTimestamp = now
            if activeTab == all.first {
                HapticFeedback.playSoft()
                collapse()
            } else {
                selectPreviousTab()
            }
            return true
        }
        
        return false
    }
    
    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()
        
        center.addObserver(
            self,
            selector: #selector(handleToggleExpanded),
            name: NSNotification.Name("com.macpulse.toggleExpanded"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        center.addObserver(
            self,
            selector: #selector(handleExpand),
            name: NSNotification.Name("com.macpulse.expand"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        center.addObserver(
            self,
            selector: #selector(handleCollapse),
            name: NSNotification.Name("com.macpulse.collapse"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        center.addObserver(
            self,
            selector: #selector(handleSwitchTab),
            name: NSNotification.Name("com.macpulse.switchTab"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        
        // Tab notifications
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.stats"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabHome), name: NSNotification.Name("com.macpulse.tab.home"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabTimer), name: NSNotification.Name("com.macpulse.tab.timer"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTimerReminder), name: NSNotification.Name("com.macpulse.timer.reminder"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabClipboard), name: NSNotification.Name("com.macpulse.tab.clipboard"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabNotes), name: NSNotification.Name("com.macpulse.tab.notes"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleToggleMirror), name: NSNotification.Name("com.macpulse.toggleMirror"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Volume & Brightness HUD notifications
        center.addObserver(self, selector: #selector(handleToggleVolumeHUD), name: NSNotification.Name("com.macpulse.toggleVolumeHUD"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleToggleBrightnessHUD), name: NSNotification.Name("com.macpulse.toggleBrightnessHUD"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTestAlert), name: NSNotification.Name("com.macpulse.testAlert"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTestReminderAlert), name: NSNotification.Name("com.macpulse.testReminderAlert"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTestToast), name: NSNotification.Name("com.macpulse.testToast"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Backward-compatible notification handlers
        center.addObserver(self, selector: #selector(handleTabHome), name: NSNotification.Name("com.macpulse.tab.live"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.vitals"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabTimer), name: NSNotification.Name("com.macpulse.tab.focus"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.history"), object: nil, suspensionBehavior: .deliverImmediately)
    }
    
    @objc private func handleTabStats() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self?.expand(to: .stats)
        }
    }
    @objc private func handleTabHome() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self?.expand(to: .home)
        }
    }
    @objc private func handleTabTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self?.expand(to: .timer)
        }
    }
    @objc private func handleTimerReminder() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            TimerService.shared.activeTab = .reminder
            self?.expand(to: .timer)
        }
    }
    @objc private func handleTabClipboard() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self?.expand(to: .clipboard)
        }
    }
    @objc private func handleTabNotes() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self?.expand(to: .notes)
        }
    }
    
    @objc private func handleToggleMirror() {
        DispatchQueue.main.async { [weak self] in
            self?.expand()
            self?.toggleCameraMirror()
        }
    }
    
    @objc private func handleExpand() {
        expand()
    }
    
    @objc private func handleCollapse() {
        collapse()
    }
    
    @objc private func handleToggleVolumeHUD() {
        toggleHUD(.volume)
    }
    
    @objc private func handleToggleBrightnessHUD() {
        toggleHUD(.brightness)
    }
    
    @objc private func handleTestAlert() {
        triggerAlert(
            icon: "timer",
            title: "Timer Completed! ⏰",
            subtitle: "25m countdown has finished.",
            actionTitle: "Repeat",
            soundName: "Glass"
        ) {
            TimerService.shared.resetCountdown()
            TimerService.shared.startCountdown()
        }
    }
    
    @objc private func handleTestReminderAlert() {
        triggerAlert(
            icon: "clock.arrow.2.circlepath",
            title: "Reminder Alert! ⏰",
            subtitle: "5m interval (Cycle #1) • Next in 5m",
            actionTitle: "Stop",
            soundName: "Glass"
        ) {
            TimerService.shared.stopReminder()
        }
    }
    
    @objc private func handleTestToast() {
        triggerToast(icon: "doc.on.doc.fill", title: "Copied!", subtitle: "Copied to clipboard")
    }
    
    @objc private func handleSwitchTab(_ notification: Notification) {
        if let tabName = notification.userInfo?["tab"] as? String {
            DispatchQueue.main.async { [weak self] in
                if let tab = MacPulseShelfTab(rawValue: tabName) {
                    self?.activeTab = tab
                }
            }
        }
    }
    
    @objc private func handleToggleExpanded() {
        toggleExpand()
    }
    
    public func toggleExpand() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isExpanded {
                self.collapse()
            } else {
                self.expand()
            }
        }
    }
    
    public func expand(to tab: MacPulseShelfTab = .home) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.show()
            self.activeTab = tab
            self.navigationDirection = .forward
            self.isExpanded = true
            self.updateWindowSize(expanded: true)
            self.startMonitoringClickOutside()
        }
    }
    
    public func collapse() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isExpanded = false
            self.activeTab = .home
            self.navigationDirection = .forward
            self.activeHUD = nil
            self.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self.showToast = false
            self.stopMonitoringClickOutside()
            self.updateWindowSize(expanded: false)
        }
    }
    
    public func toggleCameraMirror() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showCameraMirror.toggle()
            if self.showCameraMirror {
                CameraMirrorManager.shared.start()
            } else {
                CameraMirrorManager.shared.stop()
            }
        }
    }
    
    public func toggleHUD(_ type: DynamicIslandHUDType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.activeHUD == type {
                self.activeHUD = nil
                self.updateWindowSize(expanded: self.isExpanded)
            } else {
                self.activeHUD = type
                self.updateWindowSize(expanded: true)
                self.startMonitoringClickOutside()
            }
        }
    }
    
    public func dismissHUD() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activeHUD = nil
            self.updateWindowSize(expanded: self.isExpanded)
        }
    }
    
    // MARK: - Dynamic Island Alert Presentation System
    
    public func triggerAlert(
        icon: String = "timer",
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        soundName: String = "Glass",
        duration: TimeInterval = 8.0,
        onAction: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertDismissTimer?.cancel()
            self.alertActionHandler = onAction
            
            let alert = DynamicIslandAlertItem(
                icon: icon,
                title: title,
                subtitle: subtitle,
                actionTitle: actionTitle,
                soundName: soundName
            )
            
            withAnimation(MacPulseAnimations.islandSpring) {
                self.activeAlert = alert
            }
            NotificationManager.shared.playAlertSound(name: soundName)
            HapticFeedback.playSoft()
            
            // Show window if not visible
            self.show()
            self.updateWindowSize(expanded: self.isExpanded)
            
            // Auto-dismiss work item
            let work = DispatchWorkItem { [weak self] in
                self?.dismissAlert()
            }
            self.alertDismissTimer = work
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
        }
    }
    
    public func handleAlertAction() {
        DispatchQueue.main.async { [weak self] in
            let action = self?.alertActionHandler
            self?.dismissAlert()
            action?()
        }
    }
    
    public func dismissAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertDismissTimer?.cancel()
            self.alertDismissTimer = nil
            self.alertActionHandler = nil
            withAnimation(MacPulseAnimations.islandSpring) {
                self.activeAlert = nil
            }
            self.updateWindowSize(expanded: self.isExpanded)
        }
    }
    
    private func startMonitoringClickOutside() {
        stopMonitoringClickOutside()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isExpanded, let window = self.window else { return }
            let mouseLoc = NSEvent.mouseLocation
            if !window.frame.contains(mouseLoc) {
                self.collapse()
            }
        }
    }
    
    private func stopMonitoringClickOutside() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }
    
    public func triggerToast(icon: String = "checkmark.circle.fill", title: String, subtitle: String = "") {
        toastDismissTimer?.cancel()
        toastIcon = icon
        toastMessage = title
        toastSubtitle = subtitle
        withAnimation(MacPulseAnimations.islandSpring) {
            showToast = true
        }
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                self.showToast = false
            }
        }
        toastDismissTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }
    
    public func toggle() {
        if let win = window, win.isVisible {
            win.orderOut(nil)
        } else {
            show()
        }
    }
    
    public func show() {
        if window == nil {
            let (targetSize, origin) = getGeometry(expanded: isExpanded)
            let panel = DynamicIslandPanel(
                contentRect: NSRect(origin: origin, size: targetSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .statusBar + 1
            panel.hidesOnDeactivate = false
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = false
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            let hosting = FirstMouseHostingView(
                rootView: HallmarkDynamicIslandRootView()
            )
            hosting.autoresizingMask = [.width, .height]
            panel.contentView = hosting
            
            panel.setFrame(NSRect(origin: origin, size: targetSize), display: true)
            self.window = panel
        }
        
        let (targetSize, origin) = getGeometry(expanded: isExpanded)
        window?.setFrame(NSRect(origin: origin, size: targetSize), display: true)
        window?.orderFrontRegardless()
    }
    
    public func close() {
        stopMonitoringClickOutside()
        CameraMirrorManager.shared.stop()
        window?.orderOut(nil)
    }
    
    public func updateWindowSize(expanded: Bool) {
        guard let win = window else { return }
        let (targetSize, origin) = getGeometry(expanded: expanded)
        let newFrame = NSRect(origin: origin, size: targetSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.32 : 0.26
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.02, 0.25, 1.0)
            win.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func getGeometry(expanded: Bool) -> (size: NSSize, origin: CGPoint) {
        guard let screen = window?.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return (compactSize, .zero)
        }
        let targetSize: NSSize
        if activeAlert != nil {
            targetSize = MacPulseDimensions.alertIslandSize
        } else if activeHUD != nil {
            targetSize = MacPulseDimensions.hudIslandSize
        } else if expanded {
            targetSize = expandedSize
        } else if activeLiveActivityText != nil {
            targetSize = NSSize(width: 280, height: compactSize.height)
        } else {
            targetSize = compactSize
        }
        let x = screen.frame.midX - (targetSize.width / 2.0)
        let y = screen.frame.maxY - targetSize.height
        return (targetSize, CGPoint(x: x, y: y))
    }
}
