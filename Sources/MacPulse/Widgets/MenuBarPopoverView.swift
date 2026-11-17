import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var history = NetworkHistoryStore.shared
    @ObservedObject private var timer = TimerService.shared
    
    public let onToggleIsland: () -> Void
    
    public init(onToggleIsland: @escaping () -> Void) {
        self.onToggleIsland = onToggleIsland
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MacPulseTheme.accentCyan)
                    Text("MacPulse")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button("Dynamic Island") {
                    onToggleIsland()
                }
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.bordered)
            }
            
            Divider().background(MacPulseTheme.borderSubtle)
            
            // Network Speed Row
            let down = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
            let up = NetworkUnitFormatter.formatSpeed(net.currentUploadSpeed)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(MacPulseTheme.accentCyan)
                        Text("Download")
                            .font(.system(size: 10))
                            .foregroundColor(MacPulseTheme.textSecondary)
                    }
                    Text("\(down.value) \(down.unit)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(MacPulseTheme.accentPurple)
                        Text("Upload")
                            .font(.system(size: 10))
                            .foregroundColor(MacPulseTheme.textSecondary)
                    }
                    Text("\(up.value) \(up.unit)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            }
            
            // System Stats Row
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle().fill(MacPulseTheme.accentOrange).frame(width: 6, height: 6)
                    Text("CPU: \(Int(sys.cpu.usagePercentage))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(MacPulseTheme.accentBlue).frame(width: 6, height: 6)
                    Text("RAM: \(Int(sys.ram.usagePercentage))%")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
                if sys.battery.temperatureCelsius > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(MacPulseTheme.accentCyan).frame(width: 6, height: 6)
                        Text("\(String(format: "%.0f°C", sys.battery.temperatureCelsius))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            // Today's Usage
            HStack {
                Text("Today's Data:")
                    .font(.system(size: 11))
                    .foregroundColor(MacPulseTheme.textSecondary)
                Spacer()
                Text(NetworkUnitFormatter.formatBytes(history.todayDownloadBytes + history.todayUploadBytes))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(MacPulseTheme.accentCyan)
            }
            .padding(.horizontal, 4)
            
            Divider().background(MacPulseTheme.borderSubtle)
            
            // Footer actions
            HStack {
                Button("Quit MacPulse") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(MacPulseTheme.accentRed)
                .buttonStyle(.plain)
                
                Spacer()
                
                if timer.reminderState == .running {
                    Text("⏱️ Reminder Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(MacPulseTheme.accentGreen)
                } else {
                    Button("Quick Reminder (5m)") {
                        timer.setReminderInterval(seconds: 5 * 60)
                        timer.startReminder()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(MacPulseTheme.accentGreen)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(.ultraThinMaterial)
    }
}
