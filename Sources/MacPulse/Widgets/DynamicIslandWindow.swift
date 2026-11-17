import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - FirstMouseHostingView (Instant One-Click Interaction on Floating NSPanel)

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

// MARK: - Authentic Apple Notch & Island Shape (Curved Ear Layout Design)

public struct NotchShape: Shape {
    public var topCornerRadius: CGFloat
    public var bottomCornerRadius: CGFloat
    
    public init(topCornerRadius: CGFloat = 8, bottomCornerRadius: CGFloat = 14) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
    }
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { .init(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top-left ear: concave curve flowing smoothly down from menu bar into notch
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY + topCornerRadius),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.minY)
        )
        
        // Left vertical edge
        path.addLine(to: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY - bottomCornerRadius))
        
        // Bottom-left convex rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topCornerRadius + bottomCornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + topCornerRadius, y: rect.maxY)
        )
        
        // Bottom horizontal edge
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius - bottomCornerRadius, y: rect.maxY))
        
        // Bottom-right convex rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY - bottomCornerRadius),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.maxY)
        )
        
        // Right vertical edge
        path.addLine(to: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY + topCornerRadius))
        
        // Top-right ear: concave curve flowing smoothly out into menu bar
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - topCornerRadius, y: rect.minY)
        )
        
        // Top horizontal edge back to start
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

// MARK: - Dynamic Island Panel & Controller

final class DynamicIslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

public enum MacPulseShelfTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case shelf = "Shelf"
    case stats = "Stats"
    case timer = "Timer"
    case clipboard = "Clipboard"
    case notes = "Notes"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .shelf: return "tray.fill"
        case .stats: return "chart.xyaxis.line"
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

@MainActor
public final class DynamicIslandController: ObservableObject {
    public static let shared = DynamicIslandController()
    
    private var window: DynamicIslandPanel?
    @Published public var isExpanded: Bool = false
    @Published public var activeTab: MacPulseShelfTab = .home
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""
    @Published public var toastSubtitle: String = ""
    @Published public var activeLiveActivityText: String? = nil
    @Published public var activeHUD: DynamicIslandHUDType? = nil
    
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
            guard mouseLoc.y >= (screen.frame.maxY - 45) else { return }
            
            let deltaY = event.scrollingDeltaY
            if deltaY < -6 && !self.isExpanded {
                self.expand()
            } else if deltaY > 6 && self.isExpanded {
                self.collapse()
            }
        }
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
        center.addObserver(self, selector: #selector(handleTabHome), name: NSNotification.Name("com.macpulse.tab.home"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabShelf), name: NSNotification.Name("com.macpulse.tab.shelf"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.stats"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabTimer), name: NSNotification.Name("com.macpulse.tab.timer"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabClipboard), name: NSNotification.Name("com.macpulse.tab.clipboard"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabNotes), name: NSNotification.Name("com.macpulse.tab.notes"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Volume & Brightness HUD notifications
        center.addObserver(self, selector: #selector(handleToggleVolumeHUD), name: NSNotification.Name("com.macpulse.toggleVolumeHUD"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleToggleBrightnessHUD), name: NSNotification.Name("com.macpulse.toggleBrightnessHUD"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Backward-compatible notification handlers
        center.addObserver(self, selector: #selector(handleTabHome), name: NSNotification.Name("com.macpulse.tab.live"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.vitals"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabTimer), name: NSNotification.Name("com.macpulse.tab.focus"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.history"), object: nil, suspensionBehavior: .deliverImmediately)
    }
    
    @objc private func handleTabHome() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .home
            self?.expand()
        }
    }
    @objc private func handleTabShelf() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .shelf
            self?.expand()
        }
    }
    @objc private func handleTabStats() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .stats
            self?.expand()
        }
    }
    @objc private func handleTabTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .timer
            self?.expand()
        }
    }
    @objc private func handleTabClipboard() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .clipboard
            self?.expand()
        }
    }
    @objc private func handleTabNotes() {
        DispatchQueue.main.async { [weak self] in
            self?.activeHUD = nil
            self?.activeTab = .notes
            self?.expand()
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
    
    public func expand() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isExpanded = true
            self.updateWindowSize(expanded: true)
            self.startMonitoringClickOutside()
        }
    }
    
    public func collapse() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isExpanded = false
            self.activeHUD = nil
            self.showToast = false
            self.stopMonitoringClickOutside()
            self.updateWindowSize(expanded: false)
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
    
    public func triggerToast(title: String, subtitle: String) {
        toastMessage = title
        toastSubtitle = subtitle
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, self.showToast else { return }
            self.showToast = false
        }
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
        window?.orderOut(nil)
    }
    
    public func updateWindowSize(expanded: Bool) {
        guard let win = window else { return }
        let (targetSize, origin) = getGeometry(expanded: expanded)
        let newFrame = NSRect(origin: origin, size: targetSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func getGeometry(expanded: Bool) -> (size: NSSize, origin: CGPoint) {
        guard let screen = window?.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return (compactSize, .zero)
        }
        let targetSize: NSSize
        if activeHUD != nil {
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

// MARK: - Hallmark Dynamic Island Root View (Apple-Engineered Architecture)

public struct HallmarkDynamicIslandRootView: View {
    @ObservedObject private var controller = DynamicIslandController.shared
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var history = NetworkHistoryStore.shared
    @ObservedObject private var timer = TimerService.shared
    
    @State private var isHovering: Bool = false
    @State private var currentTimeString: String = ""
    @Namespace private var tabAnimationNamespace
    
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
    
    private var isAnyTimerRunning: Bool {
        timer.pomodoroState == .running || timer.countdownState == .running || timer.stopwatchState == .running
    }
    
    private var currentNotchShape: NotchShape {
        let topEar: CGFloat
        let bottomRadius: CGFloat
        if controller.activeHUD != nil {
            topEar = MacPulseRadius.topEarHUD
            bottomRadius = MacPulseRadius.bottomCornerHUD
        } else if isExpanded {
            topEar = MacPulseRadius.topEarExpanded
            bottomRadius = MacPulseRadius.bottomCornerExpanded
        } else {
            topEar = MacPulseRadius.topEarCompact
            bottomRadius = MacPulseRadius.bottomCornerCompact
        }
        return NotchShape(topCornerRadius: topEar, bottomCornerRadius: bottomRadius)
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Unified Apple Curved Notch Chassis (Zero Drop Shadow, Curved Ears)
            currentNotchShape
                .fill(MacPulseColors.islandBackground.opacity(0.96))
                .background(
                    VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                        .clipShape(currentNotchShape)
                )
                .overlay(
                    // Subtle Specular Hairline Rim Light (0.6pt)
                    currentNotchShape
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovering || isExpanded || controller.activeHUD != nil ? 0.22 : 0.12),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.6
                        )
                )
            
            // Content Switcher
            if let hud = controller.activeHUD {
                DynamicIslandHUDControlView(hudType: hud)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else if isExpanded {
                expandedShelfContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                compactPillBar
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(
            width: controller.activeHUD != nil
                ? MacPulseDimensions.hudIslandSize.width
                : (isExpanded
                    ? MacPulseDimensions.expandedIslandSize.width
                    : (controller.activeLiveActivityText != nil ? MacPulseDimensions.compactLiveActivitySize.width : MacPulseDimensions.compactIslandSize.width)),
            height: controller.activeHUD != nil
                ? MacPulseDimensions.hudIslandSize.height
                : (isExpanded ? MacPulseDimensions.expandedIslandSize.height : MacPulseDimensions.compactIslandSize.height)
        )
        .clipShape(currentNotchShape)
        .animation(MacPulseAnimations.islandSpring, value: controller.activeHUD)
        .animation(MacPulseAnimations.islandSpring, value: isExpanded)
        .animation(MacPulseAnimations.islandSpring, value: controller.activeLiveActivityText)
        .animation(MacPulseAnimations.snappySpring, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            updateClock()
        }
        .onReceive(clockTimer) { _ in
            updateClock()
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
                .frame(height: MacPulseDimensions.compactIslandSize.height)
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
                .frame(height: MacPulseDimensions.compactIslandSize.height)
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
                            withAnimation(MacPulseAnimations.islandSpring) {
                                controller.activeTab = tab
                            }
                            HapticFeedback.playSoft()
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
                currentTabView
                    .transition(.opacity)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
    
    @ViewBuilder
    private var currentTabView: some View {
        switch controller.activeTab {
        case .home:
            DynamicIslandHomeView()
        case .shelf:
            DynamicIslandShelfView()
        case .stats:
            DynamicIslandStatsView()
        case .timer:
            DynamicIslandTimerView()
        case .clipboard:
            DynamicIslandClipboardView()
        case .notes:
            DynamicIslandNotesView()
        }
    }
    
    private var activeTimerFormattedString: String {
        if timer.pomodoroState == .running {
            let mins = Int(timer.pomodoroRemaining) / 60
            let secs = Int(timer.pomodoroRemaining) % 60
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
