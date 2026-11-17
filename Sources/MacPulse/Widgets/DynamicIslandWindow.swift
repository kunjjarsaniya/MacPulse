import SwiftUI
import AppKit

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Native macOS Visual Effect View Blur (Liquid Obsidian Glass)

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - FirstMouseHostingView (Instant One-Click Interaction on Floating NSPanel)

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

// MARK: - Authentic Dynamic Island Unified Shape (G2 Continuous Cubic Bezier Ears & Squircles)

public struct DynamicIslandUnifiedShape: Shape {
    public var topRadius: CGFloat = 8
    public var bottomRadius: CGFloat = 22
    public var isExpanded: Bool = true
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        if !isExpanded {
            // Compact Mode: Continuous squircle capsule
            return Path(roundedRect: rect, cornerRadius: h / 2.0, style: .continuous)
        }
        
        let tr = min(topRadius, 8)
        let br = min(bottomRadius, 24)
        
        // Start top-left origin (0, 0) flush with screen bezel
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top-left transition: smooth cubic bezier eliminating sharp horns
        if tr > 0 {
            path.addCurve(
                to: CGPoint(x: tr, y: tr),
                control1: CGPoint(x: tr * 0.45, y: 0),
                control2: CGPoint(x: tr, y: tr * 0.55)
            )
        }
        
        // Left vertical edge
        path.addLine(to: CGPoint(x: tr > 0 ? tr : 0, y: h - br))
        
        // Bottom-left squircle corner
        path.addQuadCurve(
            to: CGPoint(x: (tr > 0 ? tr : 0) + br, y: h),
            control: CGPoint(x: tr > 0 ? tr : 0, y: h)
        )
        
        // Bottom horizontal edge
        path.addLine(to: CGPoint(x: w - (tr > 0 ? tr : 0) - br, y: h))
        
        // Bottom-right squircle corner
        path.addQuadCurve(
            to: CGPoint(x: w - (tr > 0 ? tr : 0), y: h - br),
            control: CGPoint(x: w - (tr > 0 ? tr : 0), y: h)
        )
        
        // Right vertical edge
        path.addLine(to: CGPoint(x: w - (tr > 0 ? tr : 0), y: tr > 0 ? tr : 0))
        
        // Top-right transition: smooth cubic bezier back to bezel
        if tr > 0 {
            path.addCurve(
                to: CGPoint(x: w, y: 0),
                control1: CGPoint(x: w - tr, y: tr * 0.55),
                control2: CGPoint(x: w - tr * 0.45, y: 0)
            )
        }
        
        // Close top edge flush
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        return path
    }
}

// MARK: - Dynamic Island Panel & Controller

final class DynamicIslandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

public enum MacPulseShelfTab: String, CaseIterable {
    case overview = "Live"
    case vitals = "Vitals"
    case timer = "Focus"
    case history = "History"
    
    var icon: String {
        switch self {
        case .overview: return "waveform.path.ecg"
        case .vitals: return "cpu"
        case .timer: return "timer"
        case .history: return "chart.bar"
        }
    }
}

public final class DynamicIslandController: ObservableObject {
    public static let shared = DynamicIslandController()
    
    private var window: DynamicIslandPanel?
    @Published public var isExpanded: Bool = false
    @Published public var activeTab: MacPulseShelfTab = .overview
    @Published public var showToast: Bool = false
    @Published public var toastMessage: String = ""
    @Published public var toastSubtitle: String = ""
    @Published public var activeLiveActivityText: String? = nil
    
    private var liveActivityTimer: DispatchWorkItem?
    private var scrollEventMonitor: Any?
    private var clickOutsideMonitor: Any?
    
    // Apple-Engineered Notch & Island Dimensions (Golden Proportions)
    private let compactSize = NSSize(width: 236, height: 26)
    private let expandedSize = NSSize(width: 520, height: 165)
    
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
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleToggleExpanded),
            name: NSNotification.Name("com.macpulse.toggleExpanded"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleExpand),
            name: NSNotification.Name("com.macpulse.expand"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleCollapse),
            name: NSNotification.Name("com.macpulse.collapse"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleSwitchTab),
            name: NSNotification.Name("com.macpulse.switchTab"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabLive),
            name: NSNotification.Name("com.macpulse.tab.live"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabVitals),
            name: NSNotification.Name("com.macpulse.tab.vitals"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabFocus),
            name: NSNotification.Name("com.macpulse.tab.focus"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabHistory),
            name: NSNotification.Name("com.macpulse.tab.history"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }
    
    @objc private func handleTabLive() {
        DispatchQueue.main.async { [weak self] in self?.activeTab = .overview }
    }
    @objc private func handleTabVitals() {
        DispatchQueue.main.async { [weak self] in self?.activeTab = .vitals }
    }
    @objc private func handleTabFocus() {
        DispatchQueue.main.async { [weak self] in self?.activeTab = .timer }
    }
    @objc private func handleTabHistory() {
        DispatchQueue.main.async { [weak self] in self?.activeTab = .history }
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
            self.stopMonitoringClickOutside()
            self.updateWindowSize(expanded: false)
        }
    }
    
    // Global Click-Outside Monitor to Auto-Dismiss Island
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
    @State private var selectedPresetMinutes: Int = 25
    @State private var currentTimeString: String = ""
    
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
            // Unified Obsidian Liquid Glass Chassis (Zero Drop Shadow)
            DynamicIslandUnifiedShape(
                topRadius: isExpanded ? 8 : 0,
                bottomRadius: isExpanded ? 22 : 13,
                isExpanded: isExpanded
            )
            .fill(Color(hex: "#0A0A0C").opacity(0.96))
            .background(
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                    .clipShape(
                        DynamicIslandUnifiedShape(
                            topRadius: isExpanded ? 8 : 0,
                            bottomRadius: isExpanded ? 22 : 13,
                            isExpanded: isExpanded
                        )
                    )
            )
            .overlay(
                // Subtle Specular Hairline Rim Light (0.5pt)
                DynamicIslandUnifiedShape(
                    topRadius: isExpanded ? 8 : 0,
                    bottomRadius: isExpanded ? 22 : 13,
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
        .frame(width: isExpanded ? 520 : (controller.activeLiveActivityText != nil ? 270 : 236), height: isExpanded ? 165 : 26)
        .clipShape(
            DynamicIslandUnifiedShape(
                topRadius: isExpanded ? 8 : 0,
                bottomRadius: isExpanded ? 22 : 13,
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
                    ForEach(MacPulseShelfTab.allCases, id: \.self) { tab in
                        Button {
                            controller.activeTab = tab
                            playSoftHaptic()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 9, weight: .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 10, weight: controller.activeTab == tab ? .semibold : .regular))
                            }
                            .foregroundColor(controller.activeTab == tab ? .white : Color.white.opacity(0.55))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(controller.activeTab == tab ? Color.white.opacity(0.15) : Color.clear)
                            )
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
                
                // Settings Action
                Button {
                    playSoftHaptic()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.70))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Settings")
                
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
            
            // Dynamic Body Section (108pt Content Canvas)
            Group {
                switch controller.activeTab {
                case .overview:
                    overviewSuiteView
                case .vitals:
                    detailedVitalsView
                case .timer:
                    detailedTimerView
                case .history:
                    historyTrayView
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - 3. Unified Hero Architecture (NotchNook 2-Zone Apple Layout)
    private var overviewSuiteView: some View {
        HStack(spacing: 10) {
            // Zone A: Hero Card (Left ~58%) — Today's Data & Telemetry Wave
            cardNetworkHero
                .frame(maxWidth: .infinity)
            
            // Zone B: Action Stack (Right ~42%) — Stacked Vitals + Focus Quick Controls
            VStack(spacing: 8) {
                quickVitalsCapsule
                quickFocusCapsule
            }
            .frame(width: 195)
        }
        .frame(height: 108)
    }
    
    // MARK: - Zone A: Bandwidth Hero Card
    private var cardNetworkHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top Row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "wifi")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Color(hex: "#38BDF8"))
                    Text("TODAY'S USAGE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                Spacer()
                let downSpeed = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
                Text("↓ \(downSpeed.value) \(downSpeed.unit)")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(net.currentDownloadSpeed > 500 ? Color(hex: "#38BDF8") : Color.white.opacity(0.45))
            }
            
            // Main Stat & Wave
            HStack(alignment: .bottom, spacing: 8) {
                let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                VStack(alignment: .leading, spacing: 1) {
                    Text(NetworkUnitFormatter.formatBytes(todayTotal))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    let upSpeed = NetworkUnitFormatter.formatSpeed(net.currentUploadSpeed)
                    Text("↑ \(upSpeed.value) \(upSpeed.unit)")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.40))
                }
                
                Spacer()
                
                // Real-time Antialiased Sparkline Wave
                SparklineChart(
                    data: net.downloadSpeedHistory,
                    gradient: LinearGradient(
                        colors: [Color(hex: "#38BDF8"), Color(hex: "#00F2FE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineColor: Color(hex: "#38BDF8"),
                    showFill: true,
                    strokeWidth: 1.5
                )
                .frame(width: 84, height: 32)
            }
            
            Spacer(minLength: 0)
            
            // Footer Info
            HStack(spacing: 4) {
                Circle()
                    .fill(net.isConnected ? Color(hex: "#30D158") : Color.orange)
                    .frame(width: 4, height: 4)
                let netLabel = net.wifiSSID.map { "Wi-Fi • \($0)" } ?? (net.activeInterfaceName.isEmpty ? "Connected" : "Wi-Fi (\(net.activeInterfaceName))")
                Text(netLabel)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.50))
                
                Spacer()
                
                Button("Reset") {
                    history.resetToday()
                    playSoftHaptic()
                }
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(Color.white.opacity(0.40))
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(height: 108)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }
    
    // MARK: - Zone B: Quick Action 1 — Vitals Capsule
    private var quickVitalsCapsule: some View {
        Button {
            controller.activeTab = .vitals
            playSoftHaptic()
        } label: {
            HStack(spacing: 8) {
                // Left Icon Badge
                ZStack {
                    Circle()
                        .fill(Color(hex: "#007AFF").opacity(0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: "cpu")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "#38BDF8"))
                }
                
                // Gauges
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Vitals")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                        Text("\(Int(temp))°C")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.60))
                    }
                    
                    HStack(spacing: 6) {
                        Text("CPU \(Int(sys.cpu.usagePercentage))%")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.70))
                        Text("•")
                            .font(.system(size: 7))
                            .foregroundColor(Color.white.opacity(0.30))
                        Text("RAM \(Int(sys.ram.usagePercentage))%")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.70))
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.30))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Zone B: Quick Action 2 — Focus Capsule
    private var quickFocusCapsule: some View {
        HStack(spacing: 8) {
            // Left Icon Badge
            ZStack {
                Circle()
                    .fill(Color(hex: "#30D158").opacity(0.18))
                    .frame(width: 26, height: 26)
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#30D158"))
            }
            .onTapGesture {
                controller.activeTab = .timer
                playSoftHaptic()
            }
            
            // Time Readout
            VStack(alignment: .leading, spacing: 2) {
                Text(isTimerCurrentlyRunning ? "Focusing" : "Focus Timer")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.white)
                
                Text(currentTimerDisplayTime)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isTimerCurrentlyRunning ? Color(hex: "#30D158") : Color.white.opacity(0.85))
            }
            .onTapGesture {
                controller.activeTab = .timer
                playSoftHaptic()
            }
            
            Spacer()
            
            // Circular Start/Pause Button
            Button {
                toggleTimerAction()
                playSoftHaptic()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            isTimerCurrentlyRunning
                                ? LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#FFD60A")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(hex: "#30D158"), Color(hex: "#20C997")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: isTimerCurrentlyRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 9.5, weight: .black))
                        .foregroundColor(.black)
                        .offset(x: isTimerCurrentlyRunning ? 0 : 0.8)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }
    
    // MARK: - Tab 2: Detailed Vitals View (Unified Triple Gauge + Top Process Consumers)
    private var detailedVitalsView: some View {
        HStack(spacing: 8) {
            // Left Column: Processor & Unified Memory & Battery (~52%)
            VStack(spacing: 6) {
                // Processor & Memory Metrics Row
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PROCESSOR")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.45))
                        Text("\(Int(sys.cpu.usagePercentage))% Load")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("\(sys.cpu.coreCount) Active Cores")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UNIFIED MEMORY")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.45))
                        Text("\(Int(sys.ram.usagePercentage))% Used")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#A855F7"))
                        let usedGB = Double(sys.ram.usedBytes) / 1_073_741_824.0
                        let totalGB = Double(sys.ram.totalBytes) / 1_073_741_824.0
                        Text(String(format: "%.1f/%.0f GB", usedGB, totalGB))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
                
                // Power & Thermals Row
                HStack {
                    let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#FF9F0A"))
                        Text("\(Int(temp))°C Normal")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: sys.battery.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 9))
                            .foregroundColor(sys.battery.isCharging ? Color(hex: "#30D158") : Color.white.opacity(0.70))
                        Text("\(sys.battery.percentage)% • \(sys.battery.isPluggedIn ? "Power Adapter" : "Battery")")
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.60))
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
            }
            .frame(maxWidth: .infinity)
            
            // Right Column: Top Resource Consumers (~48%)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("TOP CONSUMERS")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                    Spacer()
                    Button {
                        sys.fetchTopProcesses(limit: 3)
                        playSoftHaptic()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.40))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)
                
                if sys.topProcesses.isEmpty {
                    VStack {
                        Spacer()
                        Text("Analyzing apps...")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.40))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 3) {
                        ForEach(sys.topProcesses) { proc in
                            HStack(spacing: 5) {
                                if let img = proc.icon {
                                    Image(nsImage: img)
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(systemName: "app.dashed")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.50))
                                        .frame(width: 14, height: 14)
                                }
                                
                                Text(proc.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer(minLength: 4)
                                
                                Text(String(format: "%.0f%%", proc.cpuPercentage))
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "#38BDF8"))
                                
                                Text(proc.memoryString)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.45))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.04)))
                        }
                    }
                }
            }
            .padding(6)
            .frame(width: 200, height: 108)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
        }
        .frame(height: 108)
        .onAppear {
            sys.fetchTopProcesses(limit: 3)
        }
    }
    
    // MARK: - Tab 3: Detailed Interactive Focus Suite
    private var detailedTimerView: some View {
        HStack(spacing: 12) {
            // Mode Selectors
            VStack(alignment: .leading, spacing: 3) {
                ForEach(TimerTab.allCases, id: \.self) { tab in
                    Button {
                        timer.activeTab = tab
                        playSoftHaptic()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(timer.activeTab == tab ? Color(hex: "#38BDF8") : Color.white.opacity(0.55))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(timer.activeTab == tab ? Color(hex: "#38BDF8").opacity(0.15) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 90)
            
            // Big Counter Display
            VStack(spacing: 4) {
                Text(currentTimerDisplayTime)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                // Presets
                HStack(spacing: 4) {
                    quickPresetButton("5m", 5)
                    quickPresetButton("15m", 15)
                    quickPresetButton("25m", 25)
                    quickPresetButton("45m", 45)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Action Controls
            VStack(spacing: 6) {
                Button {
                    toggleTimerAction()
                    playSoftHaptic()
                } label: {
                    Text(isTimerCurrentlyRunning ? "Pause" : "Start")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(isTimerCurrentlyRunning ? Color(hex: "#FFD60A") : Color(hex: "#30D158")))
                }
                .buttonStyle(.plain)
                
                Button("Reset") {
                    resetTimerAction()
                    playSoftHaptic()
                }
                .font(.system(size: 9))
                .foregroundColor(Color.white.opacity(0.50))
                .buttonStyle(.plain)
            }
            .frame(width: 70)
        }
        .padding(10)
        .frame(height: 108)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.05)))
    }
    
    // MARK: - Tab 4: History Tray View (Past 7 Days Usage)
    private var historyTrayView: some View {
        HStack(spacing: 8) {
            let past = history.getPastDays(count: 7)
            ForEach(past) { day in
                VStack(spacing: 3) {
                    let total = day.bytesReceived + day.bytesSent
                    Spacer()
                    
                    let maxBytes = max(1024 * 1024 * 100, past.map { $0.bytesReceived + $0.bytesSent }.max() ?? 1)
                    let ratio = CGFloat(min(1.0, Double(total) / Double(maxBytes)))
                    
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#38BDF8"), Color(hex: "#A855F7")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: max(6, 48 * ratio))
                    
                    let datePart = day.dateString.suffix(5)
                    Text(String(datePart))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.55))
                    
                    Text(NetworkUnitFormatter.formatBytes(total))
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.70))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .frame(height: 108)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.05)))
    }
    
    private func quickPresetButton(_ label: String, _ mins: Int) -> some View {
        Button {
            setTimerDuration(mins)
            playSoftHaptic()
        } label: {
            Text(label)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundColor(selectedPresetMinutes == mins ? Color(hex: "#38BDF8") : Color.white.opacity(0.55))
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(selectedPresetMinutes == mins ? Color(hex: "#38BDF8").opacity(0.18) : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Timer Logic & Display Helpers
    private var isTimerCurrentlyRunning: Bool {
        switch timer.activeTab {
        case .countdown: return timer.countdownState == .running
        case .pomodoro: return timer.pomodoroState == .running
        case .stopwatch: return timer.stopwatchState == .running
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
    
    private var currentTimerDisplayTime: String {
        switch timer.activeTab {
        case .countdown:
            if timer.countdownState == .running || timer.countdownState == .paused {
                let mins = Int(timer.countdownRemaining) / 60
                let secs = Int(timer.countdownRemaining) % 60
                return String(format: "%02d:%02d", mins, secs)
            }
            return String(format: "%02d:00", selectedPresetMinutes)
        case .pomodoro:
            let mins = Int(timer.pomodoroRemaining) / 60
            let secs = Int(timer.pomodoroRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
        case .stopwatch:
            let total = Int(timer.stopwatchElapsed)
            let mins = total / 60
            let secs = total % 60
            let centis = Int((timer.stopwatchElapsed.truncatingRemainder(dividingBy: 1)) * 10)
            return String(format: "%02d:%02d.%d", mins, secs, centis)
        }
    }
    
    private func setTimerDuration(_ mins: Int) {
        selectedPresetMinutes = mins
        timer.setCountdownPreset(seconds: TimeInterval(mins * 60))
        controller.triggerToast(
            title: "\(mins) Minute Timer Set!",
            subtitle: "You'll get a notification in \(mins) minutes."
        )
    }
    
    private func toggleTimerAction() {
        switch timer.activeTab {
        case .countdown:
            if timer.countdownState == .running {
                timer.pauseCountdown()
            } else {
                if timer.countdownDuration != TimeInterval(selectedPresetMinutes * 60) {
                    timer.setCountdownPreset(seconds: TimeInterval(selectedPresetMinutes * 60))
                }
                timer.startCountdown()
            }
        case .pomodoro:
            if timer.pomodoroState == .running {
                timer.pausePomodoro()
            } else {
                timer.startPomodoro()
            }
        case .stopwatch:
            if timer.stopwatchState == .running {
                timer.pauseStopwatch()
            } else {
                timer.startStopwatch()
            }
        }
    }
    
    private func resetTimerAction() {
        switch timer.activeTab {
        case .countdown:
            timer.resetCountdown()
            timer.setCountdownPreset(seconds: TimeInterval(selectedPresetMinutes * 60))
        case .pomodoro:
            timer.resetPomodoro()
        case .stopwatch:
            timer.resetStopwatch()
        }
    }
}
