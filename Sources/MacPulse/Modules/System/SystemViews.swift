import SwiftUI

public struct SystemMonitorCard: View {
    @ObservedObject private var sys = SystemMonitorService.shared
    
    public init() {}
    
    public var body: some View {
        GlassCard(interactive: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(MacPulseTheme.accentOrange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "cpu")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(MacPulseTheme.accentOrange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Hardware Telemetry")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Mach kernel metrics & hardware vitals")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // System Uptime Chip
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundColor(MacPulseTheme.accentCyan)
                        Text("Uptime: \(sys.uptime.formattedUptime)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(MacPulseTheme.textSecondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
                
                Divider().background(MacPulseTheme.borderSubtle)
                
                // Row 1: CPU & RAM Cards
                HStack(alignment: .top, spacing: 16) {
                    // CPU Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(MacPulseTheme.accentOrange)
                                    .font(.system(size: 13))
                                Text("CPU LOAD")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            Text("\(sys.cpu.coreCount) Cores")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MacPulseTheme.textTertiary)
                        }
                        
                        HStack(spacing: 16) {
                            // Circular gauge
                            ZStack {
                                CircularProgressView(
                                    progress: sys.cpu.usagePercentage / 100.0,
                                    lineWidth: 8,
                                    gradient: MacPulseTheme.cpuGradient,
                                    size: 76
                                )
                                
                                VStack(spacing: 1) {
                                    Text("\(Int(sys.cpu.usagePercentage))%")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("USED")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(MacPulseTheme.textTertiary)
                                }
                            }
                            
                            // Breakdown
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(MacPulseTheme.accentOrange).frame(width: 6, height: 6)
                                    Text("User:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", sys.cpu.userPercentage))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Circle().fill(MacPulseTheme.accentRed).frame(width: 6, height: 6)
                                    Text("System:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", sys.cpu.systemPercentage))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Circle().fill(MacPulseTheme.accentGreen).frame(width: 6, height: 6)
                                    Text("Idle:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", sys.cpu.idlePercentage))%")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        SparklineChart(
                            data: sys.cpuHistory,
                            gradient: MacPulseTheme.cpuGradient,
                            lineColor: MacPulseTheme.accentOrange
                        )
                        .frame(height: 38)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                    
                    // RAM Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "memorychip.fill")
                                    .foregroundColor(MacPulseTheme.accentBlue)
                                    .font(.system(size: 13))
                                Text("MEMORY (RAM)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            Text(formatGB(sys.ram.totalBytes))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MacPulseTheme.textTertiary)
                        }
                        
                        HStack(spacing: 16) {
                            ZStack {
                                CircularProgressView(
                                    progress: sys.ram.usagePercentage / 100.0,
                                    lineWidth: 8,
                                    gradient: MacPulseTheme.ramGradient,
                                    size: 76
                                )
                                
                                VStack(spacing: 1) {
                                    Text("\(Int(sys.ram.usagePercentage))%")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("USED")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(MacPulseTheme.textTertiary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(MacPulseTheme.accentBlue).frame(width: 6, height: 6)
                                    Text("Active:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text(formatGB(sys.ram.activeBytes))
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Circle().fill(MacPulseTheme.accentPurple).frame(width: 6, height: 6)
                                    Text("Wired:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text(formatGB(sys.ram.wiredBytes))
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                HStack {
                                    Circle().fill(MacPulseTheme.accentCyan).frame(width: 6, height: 6)
                                    Text("Compressed:")
                                        .font(.system(size: 11))
                                        .foregroundColor(MacPulseTheme.textSecondary)
                                    Spacer()
                                    Text(formatGB(sys.ram.compressedBytes))
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        SparklineChart(
                            data: sys.ramHistory,
                            gradient: MacPulseTheme.ramGradient,
                            lineColor: MacPulseTheme.accentBlue
                        )
                        .frame(height: 38)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
                
                // Row 2: Disk Storage & Battery Telemetry
                HStack(alignment: .top, spacing: 16) {
                    // Disk Storage Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundColor(MacPulseTheme.accentGreen)
                                    .font(.system(size: 13))
                                Text("STORAGE (\(sys.disk.volumeName))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            Text("\(formatGB(sys.disk.usedBytes)) of \(formatGB(sys.disk.totalBytes))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Storage progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 12)
                                
                                let width = geo.size.width * CGFloat(sys.disk.usagePercentage / 100.0)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [MacPulseTheme.accentGreen, MacPulseTheme.accentCyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(6, width), height: 12)
                            }
                        }
                        .frame(height: 12)
                        
                        HStack {
                            Text("Free: \(formatGB(sys.disk.freeBytes))")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                            Spacer()
                            Text("\(Int(sys.disk.usagePercentage))% full")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(MacPulseTheme.accentGreen)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                    
                    // Battery Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: sys.battery.isCharging ? "battery.100.bolt" : "battery.100")
                                    .foregroundColor(MacPulseTheme.accentYellow)
                                    .font(.system(size: 13))
                                Text("BATTERY & POWER")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(MacPulseTheme.textSecondary)
                            }
                            Spacer()
                            StatusBadge(
                                text: sys.battery.hasBattery ? (sys.battery.isPluggedIn ? (sys.battery.isCharging ? "Charging" : "AC Power") : "On Battery") : "Desktop Mac",
                                color: sys.battery.isCharging ? MacPulseTheme.accentGreen : MacPulseTheme.accentYellow,
                                icon: sys.battery.isCharging ? "bolt.fill" : "powerplug.fill"
                            )
                        }
                        
                        if sys.battery.hasBattery {
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Text("\(sys.battery.percentage)%")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 3) {
                                    HStack(spacing: 4) {
                                        Text("Health:")
                                            .font(.system(size: 11))
                                            .foregroundColor(MacPulseTheme.textSecondary)
                                        Text("\(sys.battery.healthPercentage)% (\(sys.battery.condition))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(MacPulseTheme.accentGreen)
                                    }
                                    HStack(spacing: 4) {
                                        Text("Cycles:")
                                            .font(.system(size: 11))
                                            .foregroundColor(MacPulseTheme.textSecondary)
                                        Text("\(sys.battery.cycleCount)")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    if sys.battery.temperatureCelsius > 0 {
                                        HStack(spacing: 4) {
                                            Text("Temp:")
                                                .font(.system(size: 11))
                                                .foregroundColor(MacPulseTheme.textSecondary)
                                            Text(String(format: "%.1f°C", sys.battery.temperatureCelsius))
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("Direct AC Power Supply Connected")
                                .font(.system(size: 13))
                                .foregroundColor(MacPulseTheme.textSecondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.25))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
            }
        }
    }
    
    private func formatGB(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
        return String(format: "%.1f GB", gb)
    }
}
