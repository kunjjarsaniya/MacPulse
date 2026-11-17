import SwiftUI
import AppKit

// MARK: - Desktop Floating Widget Controller

public final class DesktopWidgetController {
    public static let shared = DesktopWidgetController()
    
    private var window: NSPanel?
    
    private init() {}
    
    public func toggle() {
        if let win = window, win.isVisible {
            win.orderOut(nil)
        } else {
            show()
        }
    }
    
    public func show() {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 100, y: 100, width: 340, height: 180),
                styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView, .resizable],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.contentView = NSHostingView(rootView: DesktopWidgetRootView())
            
            // Center on main screen top right
            if let screen = NSScreen.main {
                let rect = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(x: rect.maxX - 380, y: rect.maxY - 240))
            }
            
            self.window = panel
        }
        
        window?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Desktop Widget Root View
public struct DesktopWidgetRootView: View {
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var timer = TimerService.shared
    
    @State private var isExpanded: Bool = true
    
    public init() {}
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.35))
            
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            if isExpanded {
                expandedLayout
            } else {
                compactLayout
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.4), radius: 14, x: 0, y: 8)
        .frame(width: isExpanded ? 340 : 280, height: isExpanded ? 190 : 54)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isExpanded)
    }
    
    // 1. Compact Pill Layout
    private var compactLayout: some View {
        HStack(spacing: 12) {
            let down = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MacPulseTheme.accentCyan)
                Text("\(down.value) \(down.unit)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Text("•")
                .foregroundColor(MacPulseTheme.textTertiary)
            
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MacPulseTheme.accentOrange)
                Text("\(Int(sys.cpu.usagePercentage))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Text("•")
                .foregroundColor(MacPulseTheme.textTertiary)
            
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(MacPulseTheme.accentBlue)
                Text("\(Int(sys.ram.usagePercentage))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                isExpanded = true
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(MacPulseTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
    }
    
    // 2. Expanded Multi-Card Layout
    private var expandedLayout: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(MacPulseTheme.accentCyan)
                        .font(.system(size: 12, weight: .bold))
                    Text("MacPulse HUD")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button {
                    isExpanded = false
                } label: {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MacPulseTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(MacPulseTheme.borderSubtle)
            
            // Metrics grid
            HStack(spacing: 12) {
                // Network Live
                let down = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
                let up = NetworkUnitFormatter.formatSpeed(net.currentUploadSpeed)
                VStack(alignment: .leading, spacing: 6) {
                    Text("NETWORK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(MacPulseTheme.textTertiary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseTheme.accentCyan)
                        Text("\(down.value) \(down.unit)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseTheme.accentPurple)
                        Text("\(up.value) \(up.unit)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                
                // Hardware Gauge
                VStack(alignment: .leading, spacing: 6) {
                    Text("HARDWARE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(MacPulseTheme.textTertiary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseTheme.accentOrange)
                        Text("\(Int(sys.cpu.usagePercentage))% CPU")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseTheme.accentBlue)
                        Text("\(Int(sys.ram.usagePercentage))% RAM")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            }
            
            // Timer ticker if running
            if timer.reminderState == .running || timer.countdownState == .running {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(MacPulseTheme.accentGreen)
                        .font(.system(size: 11))
                    let remaining = timer.reminderState == .running ? timer.reminderRemaining : timer.countdownRemaining
                    let m = Int(remaining) / 60
                    let s = Int(remaining) % 60
                    Text(String(format: "Timer: %02d:%02d remaining", m, s))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 6)
            }
        }
        .padding(14)
    }
}
