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

// MARK: - Authentic Dynamic Island Unified Shape (Single Apple Squircle Chassis)

public struct DynamicIslandUnifiedShape: Shape {
    public var cornerRadius: CGFloat = 22
    public var isExpanded: Bool = true
    
    public var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        if !isExpanded {
            // Compact Mode: Continuous squircle capsule (zero wings, zero horns)
            return Path(roundedRect: rect, cornerRadius: rect.height / 2.0, style: .continuous)
        }
        // Expanded Mode: Pure continuous squircle chassis (flush Apple hardware component)
        return Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
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
    @Published public var showCameraMirror: Bool = false
    
    private var liveActivityTimer: DispatchWorkItem?
    private var scrollEventMonitor: Any?
    private var clickOutsideMonitor: Any?
    
    // Apple-Engineered Notch & Island Dimensions
    private let compactSize = NSSize(width: 236, height: 26)
    private let expandedSize = NSSize(width: 560, height: 175)
    
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
            guard let isPlugged = notif.userInfo?["isPluggedIn"] as? Bool,
                  let pct = notif.userInfo?["percentage"] as? Int else { return }
            let msg = isPlugged ? "⚡️ Charging (\(pct)%)" : "Battery Mode (\(pct)%)"
            self?.triggerLiveActivity(msg, duration: 3.5)
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
        center.addObserver(self, selector: #selector(handleToggleMirror), name: NSNotification.Name("com.macpulse.toggleMirror"), object: nil, suspensionBehavior: .deliverImmediately)
        
        // Backward-compatible notification handlers
        center.addObserver(self, selector: #selector(handleTabHome), name: NSNotification.Name("com.macpulse.tab.live"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.vitals"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabTimer), name: NSNotification.Name("com.macpulse.tab.focus"), object: nil, suspensionBehavior: .deliverImmediately)
        center.addObserver(self, selector: #selector(handleTabStats), name: NSNotification.Name("com.macpulse.tab.history"), object: nil, suspensionBehavior: .deliverImmediately)
    }
    
    @objc private func handleTabHome() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .home
            self?.expand()
        }
    }
    @objc private func handleTabShelf() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .shelf
            self?.expand()
        }
    }
    @objc private func handleTabStats() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .stats
            self?.expand()
        }
    }
    @objc private func handleTabTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .timer
            self?.expand()
        }
    }
    @objc private func handleTabClipboard() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .clipboard
            self?.expand()
        }
    }
    @objc private func handleTabNotes() {
        DispatchQueue.main.async { [weak self] in
            self?.activeTab = .notes
            self?.expand()
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
            self.showToast = false
            self.showCameraMirror = false
            CameraMirrorManager.shared.stop()
            self.stopMonitoringClickOutside()
            self.updateWindowSize(expanded: false)
        }
    }
    
    public func toggleCameraMirror() {
        showCameraMirror.toggle()
        if showCameraMirror {
            CameraMirrorManager.shared.start()
        } else {
            CameraMirrorManager.shared.stop()
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
            
            panel.contentView = FirstMouseHostingView(
                rootView: HallmarkDynamicIslandRootView()
            )
            
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
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func getGeometry(expanded: Bool) -> (size: NSSize, origin: CGPoint) {
        guard let screen = NSScreen.main else {
            return (compactSize, .zero)
        }
        let targetSize: NSSize
        if expanded {
            targetSize = expandedSize
        } else if activeLiveActivityText != nil {
            targetSize = NSSize(width: 270, height: 26)
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
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Unified Obsidian Liquid Glass Chassis (Zero Drop Shadow, Pure Apple Squircle)
            DynamicIslandUnifiedShape(
                cornerRadius: isExpanded ? 22 : 13,
                isExpanded: isExpanded
            )
            .fill(Color(hex: "#0A0A0C").opacity(0.96))
            .background(
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                    .clipShape(
                        DynamicIslandUnifiedShape(
                            cornerRadius: isExpanded ? 22 : 13,
                            isExpanded: isExpanded
                        )
                    )
            )
            .overlay(
                // Subtle Specular Hairline Rim Light (0.5pt)
                DynamicIslandUnifiedShape(
                    cornerRadius: isExpanded ? 22 : 13,
                    isExpanded: isExpanded
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovering || isExpanded ? 0.20 : 0.10),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.6
                )
            )
            
            // Content Switcher
            if isExpanded {
                expandedShelfContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                compactPillBar
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(width: isExpanded ? 560 : (controller.activeLiveActivityText != nil ? 270 : 236), height: isExpanded ? 175 : 26)
        .clipShape(
            DynamicIslandUnifiedShape(
                cornerRadius: isExpanded ? 22 : 13,
                isExpanded: isExpanded
            )
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isExpanded)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: controller.activeLiveActivityText)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isHovering)
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
        playSoftHaptic()
        controller.expand()
    }
    
    private func collapse() {
        playSoftHaptic()
        controller.collapse()
    }
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    // MARK: - 1. Compact Dynamic Island Pill (236 x 26 — Flush Screen-Top Anchor)
    private var compactPillBar: some View {
        Group {
            if let liveText = controller.activeLiveActivityText {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color(hex: "#30D158"))
                    Text(liveText)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(height: 26)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                HStack(spacing: 0) {
                    // 1. Wi-Fi Usage
                    HStack(spacing: 4.5) {
                        Image(systemName: "wifi")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "#38BDF8"))
                        
                        let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                        Text(NetworkUnitFormatter.formatBytes(todayTotal))
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Hairline Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 1, height: 10)
                    
                    Spacer(minLength: 4)
                    
                    // 2. Hardware Vitals
                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "cpu")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.60))
                            Text("\(Int(sys.cpu.usagePercentage))%")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.60))
                            Text("\(Int(sys.ram.usagePercentage))%")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                    
                    Spacer(minLength: 4)
                    
                    // Subtle Hairline Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 1, height: 10)
                    
                    Spacer(minLength: 4)
                    
                    // 3. Status Metric: Active Timer OR Thermals
                    Group {
                        if isAnyTimerRunning {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(Color(hex: "#30D158"))
                                Text(activeTimerFormattedString)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "#30D158"))
                            }
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color(hex: "#30D158").opacity(0.16)))
                        } else {
                            let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                            Text("\(Int(temp))°C")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.65))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { expand() }
                }
                .frame(height: 26)
                .padding(.horizontal, 11)
                .contentShape(Rectangle())
                .onTapGesture { expand() }
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - 2. Expanded Shelf Content
    private var expandedShelfContent: some View {
        VStack(spacing: 8) {
            // Top Navigation & Utility Bar
            HStack(spacing: 6) {
                // Segmented Capsule Tab Switcher
                HStack(spacing: 2) {
                    ForEach(MacPulseShelfTab.allCases) { tab in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                controller.activeTab = tab
                            }
                            playSoftHaptic()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 8.5, weight: .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 9.5, weight: controller.activeTab == tab ? .semibold : .regular))
                            }
                            .foregroundColor(controller.activeTab == tab ? .white : Color.white.opacity(0.55))
                            .padding(.horizontal, 7.5)
                            .padding(.vertical, 3.5)
                            .background {
                                if controller.activeTab == tab {
                                    Capsule()
                                        .fill(Color.white.opacity(0.18))
                                        .matchedGeometryEffect(id: "activeTabCapsule", in: tabAnimationNamespace)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2.5)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                
                Spacer()
                
                // Clock Stamp
                Text(currentTimeString)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))
                    .padding(.trailing, 2)
                
                // Camera Mirror Action
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        controller.toggleCameraMirror()
                    }
                    playSoftHaptic()
                } label: {
                    Image(systemName: controller.showCameraMirror ? "camera.fill" : "web.camera")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(controller.showCameraMirror ? Color(hex: "#30D158") : Color.white.opacity(0.70))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(controller.showCameraMirror ? Color(hex: "#30D158").opacity(0.20) : Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Toggle Camera Mirror")
                
                // Collapse Action
                Button {
                    collapse()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .help("Collapse Shelf")
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            
            // Dynamic Body Section (Content Canvas)
            ZStack {
                if controller.showCameraMirror {
                    DynamicIslandMirrorView()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    currentTabView
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
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
