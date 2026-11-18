import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - FirstMouseHostingView (Instant One-Click Interaction on Floating NSPanel)

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func scrollWheel(with event: NSEvent) {
        if DynamicIslandController.shared.handleScrollWheelEvent(event) {
            return
        }
        super.scrollWheel(with: event)
    }
}

// MARK: - Dynamic Island Shape (Adaptive Floating Capsule & Notch Geometry)

public struct DynamicIslandShape: Shape {
    public var isFloating: Bool
    public var topRadius: CGFloat
    public var bottomRadius: CGFloat
    
    public init(isFloating: Bool = false, topRadius: CGFloat = 8, bottomRadius: CGFloat = 14) {
        self.isFloating = isFloating
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
    }
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        if isFloating {
            // Floating Capsule Shape: 4 continuous smooth corners (True iOS Dynamic Island Capsule)
            return Path(
                roundedRect: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: topRadius,
                    bottomLeading: bottomRadius,
                    bottomTrailing: bottomRadius,
                    topTrailing: topRadius
                ),
                style: .continuous
            )
        } else {
            // Docked Notch: Concave ears flowing seamlessly down into screen bezel
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            
            // Top-left ear: concave curve flowing smoothly down from menu bar into notch
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + topRadius, y: rect.minY + topRadius),
                control: CGPoint(x: rect.minX + topRadius, y: rect.minY)
            )
            
            // Left vertical edge
            path.addLine(to: CGPoint(x: rect.minX + topRadius, y: rect.maxY - bottomRadius))
            
            // Bottom-left convex rounded corner
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + topRadius + bottomRadius, y: rect.maxY),
                control: CGPoint(x: rect.minX + topRadius, y: rect.maxY)
            )
            
            // Bottom horizontal edge
            path.addLine(to: CGPoint(x: rect.maxX - topRadius - bottomRadius, y: rect.maxY))
            
            // Bottom-right convex rounded corner
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - topRadius, y: rect.maxY - bottomRadius),
                control: CGPoint(x: rect.maxX - topRadius, y: rect.maxY)
            )
            
            // Right vertical edge
            path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY + topRadius))
            
            // Top-right ear: concave curve flowing smoothly out into menu bar
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.maxX - topRadius, y: rect.minY)
            )
            
            // Top horizontal edge back to start
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            return path
        }
    }
}

// Backward-compatible alias
public typealias NotchShape = DynamicIslandShape

// MARK: - Dynamic Island Panel & Controller

final class DynamicIslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

public enum TabTransitionDirection {
    case forward
    case backward
}

public enum MacPulseShelfTab: String, CaseIterable, Identifiable {
    case stats = "Stats"
    case home = "Home"
    case timer = "Timer"
    case clipboard = "Clipboard"
    case notes = "Notes"
    
    public var id: String { rawValue }
    
    public var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
    
    public var icon: String {
        switch self {
        case .stats: return "chart.xyaxis.line"
        case .home: return "house.fill"
        case .timer: return "timer"
        case .clipboard: return "doc.on.clipboard"
        case .notes: return "note.text"
        }
    }
}

public enum DynamicIslandHUDType: String, CaseIterable, Identifiable {
    case volume = "Volume"
    case brightness = "Brightness"
    
    public var id: String { rawValue }
}

public struct DynamicIslandAlertItem: Identifiable, Equatable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let subtitle: String
    public let actionTitle: String?
    public let soundName: String
    
    public init(
        icon: String = "timer",
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        soundName: String = "Glass"
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.soundName = soundName
    }
    
    public static func == (lhs: DynamicIslandAlertItem, rhs: DynamicIslandAlertItem) -> Bool {
        lhs.id == rhs.id
    }
}

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
    
    // Hardware Notch Detection (Automatic floating capsule for devices with topInset == 0)
    @Published public var isNotchedDisplay: Bool = false
    
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
        setupScreenObserver()
        setupScrollMonitor()
        detectScreenType()
    }
    
    public func detectScreenType() {
        guard let screen = window?.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            isNotchedDisplay = false
            return
        }
        if #available(macOS 12.0, *) {
            isNotchedDisplay = screen.safeAreaInsets.top > 0
        } else {
            isNotchedDisplay = false
        }
    }
    
    private func setupScreenObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.detectScreenType()
                self?.updateWindowSize(expanded: self?.isExpanded ?? false)
            }
        }
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
            withAnimation(MacPulseAnimations.islandSpring) {
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
            self.detectScreenType()
            
            // If collapsed: pull down gesture near top screen edge expands the island
            if !self.isExpanded {
                let thresholdY = self.isNotchedDisplay ? (screen.frame.maxY - 45) : (screen.frame.maxY - 55)
                guard mouseLoc.y >= thresholdY else { return }
                if event.scrollingDeltaY < -5 || event.scrollingDeltaY > 5 {
                    self.expand()
                }
                return
            }
            
            // If expanded: check if cursor is over the dynamic island window for gestures
            if let win = self.window, win.frame.contains(mouseLoc) {
                _ = self.handleScrollWheelEvent(event)
            }
        }
    }
    
    // MARK: - Gesture-Based Tab Navigation Engine & Scroll-to-Dismiss
    
    public func selectNextTab() {
        guard isExpanded, activeHUD == nil, !showCameraMirror else { return }
        let all = MacPulseShelfTab.allCases
        guard let currentIdx = all.firstIndex(of: activeTab), currentIdx < all.count - 1 else { return }
        navigationDirection = .forward
        withAnimation(MacPulseAnimations.islandSpring) {
            activeTab = all[currentIdx + 1]
        }
        HapticFeedback.playSoft()
    }
    
    public func selectPreviousTab() {
        guard isExpanded, activeHUD == nil, !showCameraMirror else { return }
        let all = MacPulseShelfTab.allCases
        guard let currentIdx = all.firstIndex(of: activeTab), currentIdx > 0 else { return }
        navigationDirection = .backward
        withAnimation(MacPulseAnimations.islandSpring) {
            activeTab = all[currentIdx - 1]
        }
        HapticFeedback.playSoft()
    }
    
    public func selectTab(_ tab: MacPulseShelfTab) {
        guard activeTab != tab else { return }
        navigationDirection = tab.index > activeTab.index ? .forward : .backward
        withAnimation(MacPulseAnimations.islandSpring) {
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
        let absX = abs(deltaX)
        let absY = abs(deltaY)
        
        // 1. Vertical Trackpad/Mouse Swipe-to-Dismiss (when swiped vertically towards top of screen)
        if absY > absX * 1.35 {
            if deltaY > 10 || deltaY < -10 {
                lastSwipeTimestamp = now
                isSwipeLocked = true
                HapticFeedback.playSoft()
                self.collapse()
                return true
            }
            return false
        }
        
        // 2. Horizontal Tab Navigation & Horizontal Scroll-to-Dismiss at Edges
        if !event.hasPreciseScrollingDeltas {
            let all = MacPulseShelfTab.allCases
            if deltaX < -0.4 {
                lastSwipeTimestamp = now
                isSwipeLocked = true
                if activeTab == all.last {
                    // Beyond last tab: horizontal scroll-to-dismiss!
                    HapticFeedback.playSoft()
                    self.collapse()
                } else {
                    selectNextTab()
                }
                return true
            } else if deltaX > 0.4 {
                lastSwipeTimestamp = now
                isSwipeLocked = true
                if activeTab == all.first {
                    // Beyond first tab: horizontal scroll-to-dismiss!
                    HapticFeedback.playSoft()
                    self.collapse()
                } else {
                    selectPreviousTab()
                }
                return true
            }
            return false
        }
        
        // For trackpad precise gestures, accumulate deltaX
        accumulatedDeltaX += deltaX
        
        let all = MacPulseShelfTab.allCases
        if accumulatedDeltaX < -swipeThreshold {
            accumulatedDeltaX = 0
            isSwipeLocked = true
            lastSwipeTimestamp = now
            if activeTab == all.last {
                // Swiped Left beyond last tab: horizontal scroll-to-dismiss!
                HapticFeedback.playSoft()
                self.collapse()
            } else {
                selectNextTab()
            }
            return true
        } else if accumulatedDeltaX > swipeThreshold {
            accumulatedDeltaX = 0
            isSwipeLocked = true
            lastSwipeTimestamp = now
            if activeTab == all.first {
                // Swiped Right beyond first tab: horizontal scroll-to-dismiss!
                HapticFeedback.playSoft()
                self.collapse()
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
            self.activeTab = tab
            self.navigationDirection = .forward
            withAnimation(MacPulseAnimations.dynamicIslandExpand) {
                self.isExpanded = true
            }
            self.updateWindowSize(expanded: true)
            self.startMonitoringClickOutside()
            HapticFeedback.playSoft()
        }
    }
    
    public func collapse() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            withAnimation(MacPulseAnimations.dynamicIslandCollapse) {
                self.isExpanded = false
                self.activeTab = .home
                self.navigationDirection = .forward
                self.activeHUD = nil
                self.showCameraMirror = false
                self.showToast = false
            }
            CameraMirrorManager.shared.stop()
            self.stopMonitoringClickOutside()
            self.updateWindowSize(expanded: false)
            HapticFeedback.playSoft()
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
            
            withAnimation(MacPulseAnimations.dynamicIslandExpand) {
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
            withAnimation(MacPulseAnimations.dynamicIslandCollapse) {
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
            context.duration = expanded ? 0.36 : 0.30
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func getGeometry(expanded: Bool) -> (size: NSSize, origin: CGPoint) {
        guard let screen = window?.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return (compactSize, .zero)
        }
        detectScreenType()
        
        let targetSize: NSSize
        let floatingMargin: CGFloat = expanded ? MacPulseDimensions.floatingExpandedTopMargin : MacPulseDimensions.floatingTopMargin
        
        if activeAlert != nil {
            targetSize = isNotchedDisplay ? MacPulseDimensions.alertIslandSize : MacPulseDimensions.floatingAlertSize
        } else if activeHUD != nil {
            targetSize = isNotchedDisplay ? MacPulseDimensions.hudIslandSize : MacPulseDimensions.floatingHUDSize
        } else if expanded {
            targetSize = isNotchedDisplay ? expandedSize : MacPulseDimensions.floatingExpandedSize
        } else if activeLiveActivityText != nil {
            targetSize = NSSize(width: 280, height: isNotchedDisplay ? compactSize.height : MacPulseDimensions.floatingCompactSize.height)
        } else {
            targetSize = isNotchedDisplay ? compactSize : MacPulseDimensions.floatingCompactSize
        }
        
        let x = screen.frame.midX - (targetSize.width / 2.0)
        let y: CGFloat
        if isNotchedDisplay {
            y = screen.frame.maxY - targetSize.height
        } else {
            y = screen.frame.maxY - targetSize.height - floatingMargin
        }
        return (targetSize, CGPoint(x: x, y: y))
    }
}

// MARK: - Hallmark Dynamic Island Root View (Apple-Engineered Architecture & Fluid Physics)

public struct HallmarkDynamicIslandRootView: View {
    @ObservedObject private var controller = DynamicIslandController.shared
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var history = NetworkHistoryStore.shared
    @ObservedObject private var timer = TimerService.shared
    
    @State private var isHovering: Bool = false
    @State private var currentTimeString: String = ""
    @Namespace private var tabAnimationNamespace
    
    // Interactive Gestures & Dynamic Physics State
    @State private var dragOffsetY: CGFloat = 0
    @State private var dragOffsetX: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var jellyScale: CGSize = CGSize(width: 1.0, height: 1.0)
    
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "h:mm a"
        return df
    }()
    
    private let clockTimer = Foundation.Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private var isExpanded: Bool {
        controller.isExpanded
    }
    
    private var isFloating: Bool {
        !controller.isNotchedDisplay
    }
    
    private var isAnyTimerRunning: Bool {
        timer.reminderState == .running || timer.countdownState == .running || timer.stopwatchState == .running
    }
    
    // Dynamic Corner Radii with Adaptive Swipe Interpolation
    private var currentIslandShape: DynamicIslandShape {
        let dismissProgress: CGFloat = isExpanded ? min(1.0, max(0.0, -dragOffsetY / 45.0)) : 0.0
        
        let topRadius: CGFloat
        let bottomRadius: CGFloat
        
        if isFloating {
            // Floating Capsule: continuous rounded squircle / pill
            if controller.activeAlert != nil {
                topRadius = MacPulseRadius.floatingRadiusAlert
                bottomRadius = MacPulseRadius.floatingRadiusAlert
            } else if controller.activeHUD != nil {
                topRadius = MacPulseRadius.floatingRadiusHUD
                bottomRadius = MacPulseRadius.floatingRadiusHUD
            } else if isExpanded {
                let base = MacPulseRadius.floatingRadiusExpanded
                let target = MacPulseRadius.floatingRadiusCompact
                let interpolated = base + (target - base) * dismissProgress
                topRadius = interpolated
                bottomRadius = interpolated
            } else {
                topRadius = MacPulseRadius.floatingRadiusCompact
                bottomRadius = MacPulseRadius.floatingRadiusCompact
            }
        } else {
            // Docked Notch: Concave ears + convex bottom
            let topEar: CGFloat
            let baseBottom: CGFloat
            if controller.activeAlert != nil {
                topEar = MacPulseRadius.topEarHUD
                baseBottom = MacPulseRadius.bottomCornerHUD
            } else if controller.activeHUD != nil {
                topEar = MacPulseRadius.topEarHUD
                baseBottom = MacPulseRadius.bottomCornerHUD
            } else if isExpanded {
                let baseEar = MacPulseRadius.topEarExpanded
                let targetEar = MacPulseRadius.topEarCompact
                topEar = baseEar + (targetEar - baseEar) * dismissProgress
                
                let targetBottom = MacPulseRadius.bottomCornerCompact
                baseBottom = MacPulseRadius.bottomCornerExpanded + (targetBottom - MacPulseRadius.bottomCornerExpanded) * dismissProgress
            } else {
                topEar = MacPulseRadius.topEarCompact
                baseBottom = MacPulseRadius.bottomCornerCompact
            }
            topRadius = topEar
            bottomRadius = baseBottom
        }
        
        return DynamicIslandShape(isFloating: isFloating, topRadius: topRadius, bottomRadius: bottomRadius)
    }
    
    // Swipe-Aware Blur and Specular Rim Opacity
    private var swipeAwareBlurOpacity: Double {
        if isExpanded && dragOffsetY < 0 {
            let progress = min(1.0, max(0.0, -dragOffsetY / 45.0))
            return max(0.60, 0.96 - Double(progress) * 0.36)
        }
        return 0.96
    }
    
    private var swipeAwareBorderOpacity: Double {
        if isExpanded && dragOffsetY < 0 {
            let progress = min(1.0, max(0.0, -dragOffsetY / 45.0))
            return max(0.06, 0.22 - Double(progress) * 0.16)
        }
        return isHovering || isExpanded || controller.activeHUD != nil || controller.activeAlert != nil ? 0.22 : 0.12
    }
    
    private var currentIslandWidth: CGFloat {
        if controller.activeAlert != nil {
            return isFloating ? MacPulseDimensions.floatingAlertSize.width : MacPulseDimensions.alertIslandSize.width
        } else if controller.activeHUD != nil {
            return isFloating ? MacPulseDimensions.floatingHUDSize.width : MacPulseDimensions.hudIslandSize.width
        } else if isExpanded {
            return isFloating ? MacPulseDimensions.floatingExpandedSize.width : MacPulseDimensions.expandedIslandSize.width
        } else if controller.activeLiveActivityText != nil {
            return MacPulseDimensions.compactLiveActivitySize.width
        } else {
            return isFloating ? MacPulseDimensions.floatingCompactSize.width : MacPulseDimensions.compactIslandSize.width
        }
    }
    
    private var currentIslandHeight: CGFloat {
        if controller.activeAlert != nil {
            return isFloating ? MacPulseDimensions.floatingAlertSize.height : MacPulseDimensions.alertIslandSize.height
        } else if controller.activeHUD != nil {
            return isFloating ? MacPulseDimensions.floatingHUDSize.height : MacPulseDimensions.hudIslandSize.height
        } else if isExpanded {
            return isFloating ? MacPulseDimensions.floatingExpandedSize.height : MacPulseDimensions.expandedIslandSize.height
        } else {
            return isFloating ? MacPulseDimensions.floatingCompactSize.height : MacPulseDimensions.compactIslandSize.height
        }
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Dynamic Island Shape Chassis (Floating Capsule or Docked Notch with Adaptive Blur)
            currentIslandShape
                .fill(MacPulseColors.islandBackground.opacity(swipeAwareBlurOpacity))
                .background(
                    VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                        .clipShape(currentIslandShape)
                        .opacity(swipeAwareBlurOpacity)
                )
                .overlay(
                    // Subtle Specular Hairline Rim Light (0.6pt)
                    currentIslandShape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(swipeAwareBorderOpacity),
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.6
                        )
                )
            
            // 2. Synchronized Content Interpolation & Presentation
            ZStack(alignment: .top) {
                if let alert = controller.activeAlert {
                    DynamicIslandAlertView(alert: alert)
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                } else if let hud = controller.activeHUD {
                    DynamicIslandHUDControlView(hudType: hud)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                } else if isExpanded {
                    expandedShelfContent
                        .opacity(isExpanded ? 1.0 : 0.0)
                        .scaleEffect(isExpanded ? 1.0 : 0.92, anchor: .top)
                        .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
                } else {
                    compactPillBar
                        .opacity(isExpanded ? 0.0 : 1.0)
                        .scaleEffect(isExpanded ? 0.88 : 1.0, anchor: .center)
                        .transition(.opacity.combined(with: .scale(scale: 0.90)))
                }
            }
            .animation(MacPulseAnimations.dynamicIslandExpand, value: isExpanded)
            
            // 3. Floating Toast Notification Pill
            if controller.showToast {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: controller.toastIcon.isEmpty ? "checkmark.circle.fill" : controller.toastIcon)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                        Text(controller.toastMessage)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        if !controller.toastSubtitle.isEmpty {
                            Text("• \(controller.toastSubtitle)")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.65))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.14).opacity(0.96))
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.22), lineWidth: 0.7)
                            )
                            .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)
                    )
                    .padding(.bottom, 6)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: currentIslandWidth, height: currentIslandHeight)
        .clipShape(currentIslandShape)
        .offset(x: dragOffsetX, y: dragOffsetY)
        .scaleEffect(jellyScale, anchor: .top)
        .animation(MacPulseAnimations.dynamicIslandExpand, value: isExpanded)
        .animation(MacPulseAnimations.dynamicIslandExpand, value: controller.activeAlert)
        .animation(MacPulseAnimations.dynamicIslandExpand, value: controller.activeHUD)
        .animation(MacPulseAnimations.dynamicIslandExpand, value: controller.activeLiveActivityText)
        .animation(MacPulseAnimations.snappySpring, value: isHovering)
        .animation(MacPulseAnimations.interactiveSpring, value: dragOffsetY)
        .animation(MacPulseAnimations.interactiveSpring, value: dragOffsetX)
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .onAppear {
            controller.detectScreenType()
            updateClock()
        }
        .onReceive(clockTimer) { _ in
            updateClock()
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let transX = value.translation.width
        let transY = value.translation.height
        
        if isExpanded {
            guard controller.activeHUD == nil, !controller.showCameraMirror else { return }
            isDragging = true
            
            // Vertical Drag (Swipe up to dismiss)
            if abs(transY) > abs(transX) {
                if transY < 0 {
                    // Dragging up towards dismissal: follow finger with slight resistance
                    dragOffsetY = transY * 0.85
                    let squashX = min(1.04, 1.0 + abs(transY) / 600.0)
                    let stretchY = max(0.90, 1.0 - abs(transY) / 350.0)
                    jellyScale = CGSize(width: squashX, height: stretchY)
                } else {
                    // Dragging down: rubber-band elastic resistance
                    dragOffsetY = transY * 0.22
                    jellyScale = CGSize(width: 0.99, height: 1.01)
                }
            } else {
                // Horizontal Drag (Tab navigation / edge dismiss)
                dragOffsetX = transX * 0.35
            }
        } else {
            // Collapsed Compact Pill: Pull-down-to-expand
            if transY > 0 {
                isDragging = true
                dragOffsetY = transY * 0.42
                let stretchY = min(1.22, 1.0 + (transY / 180.0))
                let squashX = max(0.95, 1.0 - (transY / 500.0))
                jellyScale = CGSize(width: squashX, height: stretchY)
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let transX = value.translation.width
        let transY = value.translation.height
        let velocityY = value.predictedEndTranslation.height - transY
        let velocityX = value.predictedEndTranslation.width - transX
        
        if isExpanded {
            if abs(transY) > abs(transX) {
                // Vertical Swipe Up to Dismiss
                if transY < -28 || velocityY < -100 {
                    HapticFeedback.playSoft()
                    collapse()
                }
            } else {
                // Horizontal Drag: Tab Navigation & Scroll-to-Dismiss at Edges
                if abs(transX) > 28 || abs(velocityX) > 90 {
                    let all = MacPulseShelfTab.allCases
                    if transX < 0 {
                        // Dragged Left
                        if controller.activeTab == all.last {
                            // Beyond last tab: horizontal scroll-to-dismiss!
                            HapticFeedback.playSoft()
                            collapse()
                        } else {
                            controller.selectNextTab()
                        }
                    } else {
                        // Dragged Right
                        if controller.activeTab == all.first {
                            // Beyond first tab: horizontal scroll-to-dismiss!
                            HapticFeedback.playSoft()
                            collapse()
                        } else {
                            controller.selectPreviousTab()
                        }
                    }
                }
            }
        } else {
            // Collapsed: Pull Down to Restore
            if transY > 20 || velocityY > 100 {
                expand()
            }
        }
        
        // Elastic rebound to rest
        withAnimation(MacPulseAnimations.jellySpring) {
            dragOffsetY = 0
            dragOffsetX = 0
            isDragging = false
            jellyScale = CGSize(width: 1.0, height: 1.0)
        }
    }
    
    private func updateClock() {
        currentTimeString = Self.timeFormatter.string(from: Date())
    }
    
    private func expand() {
        HapticFeedback.playSoft()
        controller.expand()
    }
    
    private func collapse() {
        HapticFeedback.playSoft()
        controller.collapse()
    }
    
    // MARK: - 1. Compact Dynamic Island Pill (236 x 26 — Flush Screen-Top Anchor)
    private var compactPillBar: some View {
        Group {
            if let liveText = controller.activeLiveActivityText {
                HStack(spacing: MacPulseSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.90))
                    Text(liveText)
                        .font(MacPulseTypography.footnoteRounded)
                        .foregroundColor(MacPulseColors.textPrimary)
                }
                .frame(height: isFloating ? MacPulseDimensions.floatingCompactSize.height : MacPulseDimensions.compactIslandSize.height)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                HStack(spacing: 0) {
                    Spacer(minLength: 2)
                    
                    // 1. Wi-Fi Usage
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))
                        
                        let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                        Text(NetworkUnitFormatter.formatBytes(todayTotal))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(MacPulseColors.textPrimary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Translucent Separator Dot
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 2.5, height: 2.5)
                    
                    Spacer(minLength: 4)
                    
                    // 2. Hardware Vitals (CPU & RAM)
                    HStack(spacing: 7) {
                        HStack(spacing: 2.5) {
                            Image(systemName: "cpu")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(MacPulseColors.textTertiary)
                            Text("\(Int(sys.cpu.usagePercentage))%")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textPrimary)
                        }
                        
                        HStack(spacing: 2.5) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(MacPulseColors.textTertiary)
                            Text("\(Int(sys.ram.usagePercentage))%")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textPrimary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Translucent Separator Dot
                    Circle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 2.5, height: 2.5)
                    
                    Spacer(minLength: 4)
                    
                    // 3. Status Metric: Active Timer OR Thermals
                    Group {
                        if isAnyTimerRunning {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.90))
                                Text(activeTimerFormattedString)
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.white.opacity(0.16)))
                        } else {
                            let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                            Text("\(Int(temp))°C")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(MacPulseColors.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 2)
                }
                .frame(height: isFloating ? MacPulseDimensions.floatingCompactSize.height : MacPulseDimensions.compactIslandSize.height)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - 2. Expanded Shelf Content
    private var expandedShelfContent: some View {
        VStack(spacing: MacPulseSpacing.md) {
            // Top Navigation & Utility Bar
            HStack(spacing: MacPulseSpacing.sm) {
                // Segmented Capsule Tab Switcher
                HStack(spacing: MacPulseSpacing.xxs) {
                    ForEach(MacPulseShelfTab.allCases) { tab in
                        Button {
                            controller.selectTab(tab)
                        } label: {
                            HStack(spacing: MacPulseSpacing.xs) {
                                Image(systemName: tab.icon)
                                    .font(MacPulseTypography.caption2)
                                Text(tab.rawValue)
                                    .font(controller.activeTab == tab ? MacPulseTypography.captionSemibold : MacPulseTypography.caption)
                            }
                            .foregroundColor(controller.activeTab == tab ? .white : MacPulseColors.textSecondary)
                            .padding(.horizontal, 7.5)
                            .padding(.vertical, 3.5)
                            .background {
                                if controller.activeTab == tab {
                                    Capsule()
                                        .fill(MacPulseColors.activeTabPill)
                                        .matchedGeometryEffect(id: "activeTabCapsule", in: tabAnimationNamespace)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2.5)
                .background(Capsule().fill(MacPulseColors.pillBackground))
                
                Spacer()
                
                // Clock Stamp
                Text(currentTimeString)
                    .font(MacPulseTypography.footnoteMedium)
                    .foregroundColor(MacPulseColors.textTertiary)
                    .padding(.trailing, 2)
                
                // Brightness Control Action
                IslandIconButton(
                    icon: "sun.max.fill",
                    iconSize: 10,
                    iconWeight: .medium,
                    foregroundColor: controller.activeHUD == .brightness ? .white : MacPulseColors.textSecondary,
                    backgroundColor: controller.activeHUD == .brightness ? Color.white.opacity(0.20) : Color.white.opacity(0.08),
                    tooltip: "Display Brightness"
                ) {
                    withAnimation(MacPulseAnimations.islandSpring) {
                        controller.toggleHUD(.brightness)
                    }
                }
                
                // Sound / Volume Control Action
                IslandIconButton(
                    icon: "speaker.wave.2.fill",
                    iconSize: 10,
                    iconWeight: .medium,
                    foregroundColor: controller.activeHUD == .volume ? .white : MacPulseColors.textSecondary,
                    backgroundColor: controller.activeHUD == .volume ? Color.white.opacity(0.20) : Color.white.opacity(0.08),
                    tooltip: "Sound Volume"
                ) {
                    withAnimation(MacPulseAnimations.islandSpring) {
                        controller.toggleHUD(.volume)
                    }
                }
                
                // Collapse Action
                IslandIconButton(
                    icon: "chevron.up",
                    iconSize: 9,
                    iconWeight: .bold,
                    foregroundColor: MacPulseColors.textPrimary,
                    backgroundColor: Color.white.opacity(0.10),
                    tooltip: "Collapse Shelf"
                ) {
                    collapse()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 9)
            
            // Dynamic Body Section (Content Canvas)
            ZStack {
                if controller.showCameraMirror {
                    DynamicIslandMirrorView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    currentTabView
                        .id(controller.activeTab)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: controller.navigationDirection == .forward ? .trailing : .leading).combined(with: .opacity),
                                removal: .move(edge: controller.navigationDirection == .forward ? .leading : .trailing).combined(with: .opacity)
                            )
                        )
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { gesture in
                        guard controller.isExpanded, controller.activeHUD == nil, !controller.showCameraMirror else { return }
                        let transX = gesture.translation.width
                        let transY = gesture.translation.height
                        guard abs(transX) > abs(transY) * 1.35 else { return }
                        let all = MacPulseShelfTab.allCases
                        if transX < -30 {
                            if controller.activeTab == all.last {
                                controller.collapse()
                            } else {
                                controller.selectNextTab()
                            }
                        } else if transX > 30 {
                            if controller.activeTab == all.first {
                                controller.collapse()
                            } else {
                                controller.selectPreviousTab()
                            }
                        }
                    }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var currentTabView: some View {
        switch controller.activeTab {
        case .stats:
            DynamicIslandStatsView()
        case .home:
            DynamicIslandHomeView()
        case .timer:
            DynamicIslandTimerView()
        case .clipboard:
            DynamicIslandClipboardView()
        case .notes:
            DynamicIslandNotesView()
        }
    }
    
    private var activeTimerFormattedString: String {
        if timer.reminderState == .running {
            let mins = Int(timer.reminderRemaining) / 60
            let secs = Int(timer.reminderRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
        } else if timer.countdownState == .running {
            let mins = Int(timer.countdownRemaining) / 60
            let secs = Int(timer.countdownRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
        } else if timer.stopwatchState == .running {
            let totalSeconds = Int(timer.stopwatchElapsed)
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            return String(format: "%02d:%02d", mins, secs)
        }
        return "00:00"
    }
}
