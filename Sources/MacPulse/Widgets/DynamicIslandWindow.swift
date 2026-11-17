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

// MARK: - Native macOS Visual Effect View Blur (Liquid Glassmorphism)

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

// MARK: - Authentic MacBook Notch Shelf Shape (Concave Top Ears + Rounded Bottom Squircles)

struct NotchNookShelfShape: Shape {
    var earRadius: CGFloat = 12
    var bottomRadius: CGFloat = 20
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let er = earRadius
        let br = bottomRadius
        
        // Start at top-left origin (0, 0)
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top-left smooth concave ear flair (curves inward from top edge to the shelf body)
        path.addQuadCurve(
            to: CGPoint(x: er, y: er),
            control: CGPoint(x: er, y: 0)
        )
        
        // Left edge straight down to before bottom-left corner
        path.addLine(to: CGPoint(x: er, y: h - br))
        
        // Bottom-left convex squircle corner
        path.addQuadCurve(
            to: CGPoint(x: er + br, y: h),
            control: CGPoint(x: er, y: h)
        )
        
        // Bottom edge straight across to before bottom-right corner
        path.addLine(to: CGPoint(x: w - er - br, y: h))
        
        // Bottom-right convex squircle corner
        path.addQuadCurve(
            to: CGPoint(x: w - er, y: h - br),
            control: CGPoint(x: w - er, y: h)
        )
        
        // Right edge straight up to before top-right ear flair
        path.addLine(to: CGPoint(x: w - er, y: er))
        
        // Top-right smooth concave ear flair (curves outward back to the top edge)
        path.addQuadCurve(
            to: CGPoint(x: w, y: 0),
            control: CGPoint(x: w - er, y: 0)
        )
        
        // Top edge straight across closing the shape at the display bezel
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
    case overview = "Overview"
    case vitals = "Vitals"
    case timer = "Focus"
    case history = "History"
    
    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
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
    
    private var clickOutsideMonitor: Any?
    
    // Balanced Dimensions (Flush to Top Bezel)
    private let compactSize = NSSize(width: 258, height: 28)
    private let expandedSize = NSSize(width: 660, height: 142)
    
    private init() {
        setupDistributedNotifications()
    }
    
    private func setupDistributedNotifications() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleToggleExpanded),
            name: NSNotification.Name("com.macpulse.toggleExpanded"),
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
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
            
            panel.contentView = NSHostingView(
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
            return (NSSize(width: 258, height: 28), .zero)
        }
        let targetSize = expanded ? expandedSize : compactSize
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
            // Background Liquid Glass Obsidian Chassis
            NotchNookShelfShape(earRadius: isExpanded ? 12 : 6, bottomRadius: isExpanded ? 20 : 10)
                .fill(Color.black.opacity(0.96))
                .background(
                    VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                        .clipShape(NotchNookShelfShape(earRadius: isExpanded ? 12 : 6, bottomRadius: isExpanded ? 20 : 10))
                )
                .overlay(
                    // Subtle Specular Perimeter Rim Light
                    NotchNookShelfShape(earRadius: isExpanded ? 12 : 6, bottomRadius: isExpanded ? 20 : 10)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovering || isExpanded ? 0.22 : 0.12),
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
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
        .frame(width: isExpanded ? 660 : 258, height: isExpanded ? 142 : 28)
        .clipShape(NotchNookShelfShape(earRadius: isExpanded ? 12 : 6, bottomRadius: isExpanded ? 20 : 10))
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isExpanded)
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
    
    // MARK: - 1. Compact Notch Bar (258 x 28 — Flush to Top Screen Bezel)
    private var compactPillBar: some View {
        HStack(spacing: 0) {
            // 1. Wi-Fi Usage
            HStack(spacing: 5) {
                Image(systemName: "wifi")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(Color(hex: "#38BDF8"))
                
                let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                Text(NetworkUnitFormatter.formatBytes(todayTotal))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .contentShape(Rectangle())
            .onTapGesture { expand() }
            
            Spacer()
            
            // Elegant Hairline Divider
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1, height: 11)
            
            Spacer()
            
            // 2. Hardware Vitals (CPU & RAM)
            HStack(spacing: 7) {
                HStack(spacing: 3) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.60))
                    Text("\(Int(sys.cpu.usagePercentage))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 3) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.60))
                    Text("\(Int(sys.ram.usagePercentage))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { expand() }
            
            Spacer()
            
            // Elegant Hairline Divider
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1, height: 11)
            
            Spacer()
            
            // 3. Status Metric: Active Timer OR Thermals
            Group {
                if isAnyTimerRunning {
                    HStack(spacing: 3.5) {
                        Image(systemName: "timer")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#30D158"))
                        Text(activeTimerFormattedString)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#30D158"))
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: "#30D158").opacity(0.16)))
                } else {
                    let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                    Text("\(Int(temp))°C")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.65))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { expand() }
        }
        .frame(height: 28)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        .onTapGesture { expand() }
    }
    
    // MARK: - 2. Expanded Shelf Content
    private var expandedShelfContent: some View {
        VStack(spacing: 7) {
            // Top Navigation & Utility Bar
            HStack(spacing: 6) {
                // Segmented Tab Switcher
                HStack(spacing: 2) {
                    ForEach(MacPulseShelfTab.allCases, id: \.self) { tab in
                        Button {
                            controller.activeTab = tab
                            playSoftHaptic()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 8.5, weight: .medium))
                                Text(tab.rawValue)
                                    .font(.system(size: 10, weight: controller.activeTab == tab ? .semibold : .regular))
                            }
                            .foregroundColor(controller.activeTab == tab ? .white : Color.white.opacity(0.55))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(controller.activeTab == tab ? Color.white.opacity(0.16) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                
                Spacer()
                
                // Clock Stamp
                Text(currentTimeString)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.60))
                    .padding(.trailing, 2)
                
                // Settings Action
                Button {
                    playSoftHaptic()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.70))
                        .frame(width: 20, height: 20)
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
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Collapse Shelf")
            }
            .padding(.horizontal, 14)
            .padding(.top, 7)
            
            // Dynamic Body Section
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
            .padding(.bottom, 9)
        }
    }
    
    // MARK: - 3. Signature Overview Suite (3-Card Harmonized Apple Architecture)
    private var overviewSuiteView: some View {
        HStack(spacing: 8) {
            // Card 1: Today's Internet Usage & Telemetry Wave
            cardNetworkOverview
                .frame(maxWidth: .infinity)
            
            // Card 2: System Telemetry & Micro-Gauges
            cardSystemOverview
                .frame(maxWidth: .infinity)
            
            // Card 3: Focus & Timer Quick Control
            cardTimerOverview
                .frame(width: 170)
        }
    }
    
    // MARK: - Card 1: Network & Bandwidth Card
    private var cardNetworkOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "wifi")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#38BDF8"))
                    Text("TODAY'S DATA")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                Spacer()
                let downSpeed = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
                Text("↓\(downSpeed.value) \(downSpeed.unit)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(net.currentDownloadSpeed > 500 ? Color(hex: "#38BDF8") : Color.white.opacity(0.45))
            }
            
            // Metric & Wave
            HStack(alignment: .bottom, spacing: 8) {
                let todayTotal = history.todayDownloadBytes + history.todayUploadBytes
                VStack(alignment: .leading, spacing: 1) {
                    Text(NetworkUnitFormatter.formatBytes(todayTotal))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
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
                .frame(width: 68, height: 26)
            }
            
            // Footer Info
            HStack(spacing: 4) {
                Circle()
                    .fill(net.isConnected ? Color(hex: "#30D158") : Color.orange)
                    .frame(width: 4, height: 4)
                Text(net.activeInterfaceName.isEmpty ? "Connected" : net.activeInterfaceName)
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
        .padding(9)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }
    
    // MARK: - Card 2: System Telemetry Card
    private var cardSystemOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#A855F7"))
                    Text("SYSTEM VITALS")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                Spacer()
                Text("\(sys.cpu.coreCount) Cores")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.40))
            }
            
            // Progress Micro-Gauges
            VStack(spacing: 5) {
                // CPU Bar
                HStack(spacing: 6) {
                    Text("CPU")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.60))
                        .frame(width: 25, alignment: .leading)
                    
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#38BDF8"), Color(hex: "#00F2FE")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, g.size.width * CGFloat(min(1.0, sys.cpu.usagePercentage / 100.0))))
                        }
                    }
                    .frame(height: 4)
                    
                    Text("\(Int(sys.cpu.usagePercentage))%")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, alignment: .trailing)
                }
                
                // RAM Bar
                HStack(spacing: 6) {
                    Text("RAM")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.60))
                        .frame(width: 25, alignment: .leading)
                    
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#A855F7"), Color(hex: "#EC4899")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, g.size.width * CGFloat(min(1.0, sys.ram.usagePercentage / 100.0))))
                        }
                    }
                    .frame(height: 4)
                    
                    Text("\(Int(sys.ram.usagePercentage))%")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, alignment: .trailing)
                }
            }
            
            // Footer: Thermals & Battery
            HStack {
                let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                HStack(spacing: 3) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 8.5))
                        .foregroundColor(Color(hex: "#FF9F0A"))
                    Text("\(Int(temp))°C")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.70))
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Image(systemName: sys.battery.isCharging ? "bolt.fill" : "battery.75")
                        .font(.system(size: 8.5))
                        .foregroundColor(sys.battery.isCharging ? Color(hex: "#30D158") : Color.white.opacity(0.70))
                    Text("\(sys.battery.percentage)%")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.70))
                }
            }
        }
        .padding(9)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }
    
    // MARK: - Card 3: Focus & Timer Card
    private var cardTimerOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#30D158"))
                    Text("FOCUS")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                Spacer()
                Text(isTimerCurrentlyRunning ? "Active" : "Idle")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(isTimerCurrentlyRunning ? Color(hex: "#30D158") : Color.white.opacity(0.40))
            }
            
            // Readout & Start Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(currentTimerDisplayTime)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(selectedPresetMinutes)m target")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.40))
                }
                
                Spacer()
                
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
                            .frame(width: 30, height: 30)
                            .shadow(color: (isTimerCurrentlyRunning ? Color(hex: "#FF9F0A") : Color(hex: "#30D158")).opacity(0.35), radius: 4)
                        
                        Image(systemName: isTimerCurrentlyRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 10.5, weight: .black))
                            .foregroundColor(.black)
                            .offset(x: isTimerCurrentlyRunning ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Quick Presets
            HStack(spacing: 4) {
                quickPresetButton("15m", 15)
                quickPresetButton("25m", 25)
                quickPresetButton("45m", 45)
                
                Spacer()
                
                Button("Reset") {
                    resetTimerAction()
                    playSoftHaptic()
                }
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(Color.white.opacity(0.40))
                .buttonStyle(.plain)
            }
        }
        .padding(9)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
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
    
    // MARK: - Tab 2: Detailed Vitals View
    private var detailedVitalsView: some View {
        HStack(spacing: 12) {
            // CPU Deep Dive
            VStack(alignment: .leading, spacing: 4) {
                Text("PROCESSOR")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                Text("\(Int(sys.cpu.usagePercentage))% Load")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(sys.cpu.coreCount) Active Cores")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            
            // Memory Deep Dive
            VStack(alignment: .leading, spacing: 4) {
                Text("UNIFIED MEMORY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                Text("\(Int(sys.ram.usagePercentage))% Used")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#A855F7"))
                let usedGB = Double(sys.ram.usedBytes) / 1_073_741_824.0
                let totalGB = Double(sys.ram.totalBytes) / 1_073_741_824.0
                Text(String(format: "%.1f GB of %.0f GB", usedGB, totalGB))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            
            // Power & Thermals
            VStack(alignment: .leading, spacing: 4) {
                Text("THERMALS & POWER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.45))
                let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                Text("\(Int(temp))°C Normal")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#FF9F0A"))
                Text("\(sys.battery.percentage)% Battery • \(sys.battery.isCharging ? "Charging" : "Discharging")")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.50))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        }
        .frame(height: 92)
    }
    
    // MARK: - Tab 3: Detailed Interactive Focus Suite
    private var detailedTimerView: some View {
        HStack(spacing: 14) {
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
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(timer.activeTab == tab ? Color(hex: "#38BDF8") : Color.white.opacity(0.6))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 6).fill(timer.activeTab == tab ? Color(hex: "#38BDF8").opacity(0.15) : Color.clear))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 95)
            
            // Big Counter Display
            VStack(spacing: 2) {
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
            VStack(spacing: 5) {
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
                .font(.system(size: 9.5))
                .foregroundColor(Color.white.opacity(0.65))
                .buttonStyle(.plain)
            }
            .frame(width: 70)
        }
        .padding(10)
        .frame(height: 92)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
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
                    
                    RoundedRectangle(cornerRadius: 3)
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
        .frame(height: 92)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
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
