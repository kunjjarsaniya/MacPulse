import SwiftUI

public struct NetworkMonitorCard: View {
    @ObservedObject private var netService = NetworkMonitorService.shared
    @ObservedObject private var historyStore = NetworkHistoryStore.shared
    
    @State private var selectedHistoryRange: HistoryRange = .past7Days
    
    enum HistoryRange: String, CaseIterable, CustomStringConvertible {
        case past7Days = "7 Days"
        case past14Days = "14 Days"
        
        var description: String { self.rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        GlassCard(interactive: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(MacPulseTheme.accentCyan.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "wifi")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(MacPulseTheme.accentCyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wi-Fi & Network Monitor")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Real-time bandwidth & daily telemetry")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Connection Status & Interface Selector
                    HStack(spacing: 8) {
                        StatusBadge(
                            text: netService.isConnected ? "\(netService.connectionType) Connected" : "Disconnected",
                            color: netService.isConnected ? MacPulseTheme.accentGreen : MacPulseTheme.accentRed,
                            icon: netService.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        
                        // Interface selector menu
                        Menu {
                            Button("Auto (\(netService.activeInterfaceName))") {
                                netService.selectedInterfaceOption = "auto"
                            }
                            Button("All Interfaces") {
                                netService.selectedInterfaceOption = "all"
                            }
                            Divider()
                            ForEach(netService.availableInterfaces) { iface in
                                Button(iface.displayName) {
                                    netService.selectedInterfaceOption = iface.name
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11))
                                Text(netService.selectedInterfaceOption == "auto" ? "Auto" : netService.selectedInterfaceOption)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(MacPulseTheme.textSecondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.06))
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                
                Divider()
                    .background(MacPulseTheme.borderSubtle)
                
                // Live Speed Meters: Download & Upload
                HStack(spacing: 16) {
                    // Download Speed Card
                    let downSpeed = NetworkUnitFormatter.formatSpeed(netService.currentDownloadSpeed)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(MacPulseTheme.accentCyan)
                                    .font(.system(size: 14))
                                Text("DOWNLOAD SPEED")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            Text("Peak: \(NetworkUnitFormatter.formatSpeed(historyStore.peakDownloadSpeed).value) \(NetworkUnitFormatter.formatSpeed(historyStore.peakDownloadSpeed).unit)")
                                .font(.system(size: 10))
                                .foregroundColor(MacPulseTheme.textTertiary)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(downSpeed.value)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(downSpeed.unit)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(MacPulseTheme.accentCyan)
                        }
                        
                        // Live sparkline
                        SparklineChart(
                            data: netService.downloadSpeedHistory,
                            gradient: MacPulseTheme.downloadGradient,
                            lineColor: MacPulseTheme.accentCyan
                        )
                        .frame(height: 44)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                    
                    // Upload Speed Card
                    let upSpeed = NetworkUnitFormatter.formatSpeed(netService.currentUploadSpeed)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(MacPulseTheme.accentPurple)
                                    .font(.system(size: 14))
                                Text("UPLOAD SPEED")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            Text("Peak: \(NetworkUnitFormatter.formatSpeed(historyStore.peakUploadSpeed).value) \(NetworkUnitFormatter.formatSpeed(historyStore.peakUploadSpeed).unit)")
                                .font(.system(size: 10))
                                .foregroundColor(MacPulseTheme.textTertiary)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(upSpeed.value)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text(upSpeed.unit)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(MacPulseTheme.accentPurple)
                        }
                        
                        // Live sparkline
                        SparklineChart(
                            data: netService.uploadSpeedHistory,
                            gradient: MacPulseTheme.uploadGradient,
                            lineColor: MacPulseTheme.accentPurple
                        )
                        .frame(height: 44)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
                
                // Today's Cumulative Usage Strip
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY'S USAGE (MIDNIGHT RESET)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                        
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Circle().fill(MacPulseTheme.accentCyan).frame(width: 8, height: 8)
                                Text("Downloaded:")
                                    .font(.system(size: 12))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                Text(NetworkUnitFormatter.formatBytes(historyStore.todayDownloadBytes))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 6) {
                                Circle().fill(MacPulseTheme.accentPurple).frame(width: 8, height: 8)
                                Text("Uploaded:")
                                    .font(.system(size: 12))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                Text(NetworkUnitFormatter.formatBytes(historyStore.todayUploadBytes))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            
                            HStack(spacing: 6) {
                                Circle().fill(MacPulseTheme.accentGreen).frame(width: 8, height: 8)
                                Text("Total Combined:")
                                    .font(.system(size: 12))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                                    .lineLimit(1)
                                    .fixedSize()
                                Text(NetworkUnitFormatter.formatBytes(historyStore.todayDownloadBytes + historyStore.todayUploadBytes))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(MacPulseTheme.accentGreen)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button {
                                historyStore.resetToday()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10))
                                    Text("Reset")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(MacPulseTheme.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                )
                
                // History Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("USAGE HISTORY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                        Spacer()
                        SegmentedPillPicker(selection: $selectedHistoryRange, items: HistoryRange.allCases)
                    }
                    
                    let daysCount = (selectedHistoryRange == .past7Days) ? 7 : 14
                    let historyDays = historyStore.getPastDays(count: daysCount)
                    
                    NetworkHistoryBarChart(records: historyDays)
                        .frame(height: 120)
                }
            }
        }
    }
}

// MARK: - Daily Usage Bar Chart
public struct NetworkHistoryBarChart: View {
    public let records: [DailyNetworkUsageRecord]
    
    public init(records: [DailyNetworkUsageRecord]) {
        self.records = records
    }
    
    private var maxUsage: UInt64 {
        let maxVal = records.map { $0.bytesReceived + $0.bytesSent }.max() ?? 1
        return max(maxVal, 1024 * 1024 * 100) // at least 100MB scale
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(records) { record in
                let total = record.bytesReceived + record.bytesSent
                let heightRatio = min(Double(total) / Double(maxUsage), 1.0)
                
                VStack(spacing: 6) {
                    // Tooltip-style value on hover
                    Text(NetworkUnitFormatter.formatBytes(total))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(total > 0 ? MacPulseTheme.textSecondary : MacPulseTheme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Bar
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.05))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer()
                                
                                let totalHeight = geo.size.height * CGFloat(heightRatio)
                                let downRatio = total > 0 ? Double(record.bytesReceived) / Double(total) : 0.5
                                let upRatio = 1.0 - downRatio
                                
                                VStack(spacing: 1) {
                                    // Upload portion
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(MacPulseTheme.accentPurple)
                                        .frame(height: max(2, totalHeight * CGFloat(upRatio)))
                                    
                                    // Download portion
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(MacPulseTheme.accentCyan)
                                        .frame(height: max(2, totalHeight * CGFloat(downRatio)))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .frame(height: 70)
                    
                    // Date label (e.g. "Mon" or "11/15")
                    Text(shortDate(record.dateString))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MacPulseTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private func shortDate(_ str: String) -> String {
        let parts = str.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return str
    }
}
