import SwiftUI
import AppKit

// MARK: - Wi-Fi Desktop Widget Controller

public final class WiFiWidgetController {
    public static let shared = WiFiWidgetController()
    
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
                contentRect: NSRect(x: 120, y: 120, width: 220, height: 220),
                styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.hidesOnDeactivate = false
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.contentView = NSHostingView(rootView: WiFiDesktopWidgetView())
            
            // Position on desktop (bottom right or default visible screen frame)
            if let screen = NSScreen.main {
                let rect = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(x: rect.maxX - 260, y: rect.minY + 80))
            }
            
            self.window = panel
        }
        
        window?.orderFrontRegardless()
    }
    
    public func close() {
        window?.orderOut(nil)
    }
}

// MARK: - Wi-Fi Desktop Widget View (Exact replica of user screenshot)

public struct WiFiDesktopWidgetView: View {
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var history = NetworkHistoryStore.shared
    
    @State private var showLiveSpeed: Bool = false
    @State private var lastUpdatedDate: Date = Date()
    @State private var isSpinning: Bool = false
    
    private let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy, h:mm a"
        return df
    }()
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Widget rounded background
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 14) {
                // Header: Circular Blue Wi-Fi Icon + WI-FI DATA USAGE
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.00, green: 0.48, blue: 1.00)) // Apple bright blue #007AFF
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "wifi")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("WI-FI DATA USAGE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(white: 0.65))
                        .tracking(0.5)
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                // Data Rows (Download & Upload)
                VStack(spacing: 12) {
                    // Download Row
                    HStack(spacing: 12) {
                        // Green square icon with down arrow
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.18, green: 0.80, blue: 0.28)) // Vibrant Green #2FD158
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "arrow.down")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.black)
                        }
                        
                        // Value
                        if showLiveSpeed {
                            let speed = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(speed.value)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text(speed.unit)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.28))
                            }
                        } else {
                            Text(formatGB(history.todayDownloadBytes))
                                .font(.system(size: 23, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    // Subtle Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)
                        .padding(.horizontal, 2)
                    
                    // Upload Row
                    HStack(spacing: 12) {
                        // Purple square icon with up arrow
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 0.12, green: 0.08, blue: 0.18))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(red: 0.75, green: 0.25, blue: 0.95), lineWidth: 2)
                                )
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(Color(red: 0.80, green: 0.35, blue: 0.98))
                        }
                        
                        // Value
                        if showLiveSpeed {
                            let speed = NetworkUnitFormatter.formatSpeed(net.currentUploadSpeed)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(speed.value)
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text(speed.unit)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(red: 0.75, green: 0.25, blue: 0.95))
                            }
                        } else {
                            Text(formatGB(history.todayUploadBytes))
                                .font(.system(size: 23, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Footer: Refresh icon + Timestamp
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isSpinning.toggle()
                        }
                        lastUpdatedDate = Date()
                        net.discoverInterfaces()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.55))
                            .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    }
                    .buttonStyle(.plain)
                    
                    Text(timeFormatter.string(from: lastUpdatedDate))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(white: 0.55))
                    
                    Spacer()
                    
                    // Mode indicator badge (Today / Live)
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            showLiveSpeed.toggle()
                        }
                    } label: {
                        Text(showLiveSpeed ? "LIVE" : "TODAY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(showLiveSpeed ? Color(red: 0.00, green: 0.78, blue: 0.74) : Color(white: 0.55))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Click to toggle between Today's Total Usage and Live Bandwidth Speed")
                }
            }
            .padding(18)
        }
        .frame(width: 220, height: 215)
        .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 8)
        .contextMenu {
            Button("Switch to \(showLiveSpeed ? "Today's Total" : "Live Speed")") {
                showLiveSpeed.toggle()
            }
            Button("Reset Today's Usage") {
                history.resetToday()
                lastUpdatedDate = Date()
            }
            Divider()
            Button("Open MacPulse Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                if let win = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
                    win.makeKeyAndOrderFront(nil)
                }
            }
            Button("Close Widget") {
                WiFiWidgetController.shared.close()
            }
        }
    }
    
    private func formatGB(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.2f GB", gb)
    }
}
