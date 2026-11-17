import AppKit
import SwiftUI

// MARK: - Dynamic Island Stats View (Hardware Telemetry & Top Process Consumers)

public struct DynamicIslandStatsView: View {
    @ObservedObject private var sys = SystemMonitorService.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: MacPulseSpacing.md) {
            vitalsColumn
                .frame(maxWidth: .infinity)
            
            topConsumersColumn
                .frame(width: 220, height: MacPulseDimensions.contentHeight)
        }
        .frame(height: MacPulseDimensions.contentHeight)
        .onAppear {
            sys.fetchTopProcesses(limit: 3)
        }
    }
    
    // MARK: - Left Vitals Column
    private var vitalsColumn: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            // CPU & RAM Row
            IslandCard(cornerRadius: MacPulseRadius.card) {
                HStack(spacing: MacPulseSpacing.sm) {
                    VStack(alignment: .leading, spacing: MacPulseSpacing.xxs) {
                        Text("PROCESSOR")
                            .font(MacPulseTypography.caption2Bold)
                            .foregroundColor(MacPulseColors.textTertiary)
                        Text("\(Int(sys.cpu.usagePercentage))% Load")
                            .font(MacPulseTypography.metric)
                            .foregroundColor(MacPulseColors.textPrimary)
                        Text("\(sys.cpu.coreCount) Active Cores")
                            .font(MacPulseTypography.caption2)
                            .foregroundColor(MacPulseColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: MacPulseSpacing.xxs) {
                        Text("UNIFIED MEMORY")
                            .font(MacPulseTypography.caption2Bold)
                            .foregroundColor(MacPulseColors.textTertiary)
                        Text("\(Int(sys.ram.usagePercentage))% Used")
                            .font(MacPulseTypography.metric)
                            .foregroundColor(MacPulseColors.applePurple)
                        let usedGB = Double(sys.ram.usedBytes) / 1_073_741_824.0
                        let totalGB = Double(sys.ram.totalBytes) / 1_073_741_824.0
                        Text(String(format: "%.1f/%.0f GB", usedGB, totalGB))
                            .font(MacPulseTypography.caption2)
                            .foregroundColor(MacPulseColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(MacPulseSpacing.md)
            }
            
            // Power & Thermals Row
            IslandCard(cornerRadius: MacPulseRadius.card) {
                HStack {
                    let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
                    HStack(spacing: MacPulseSpacing.xs) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 9))
                            .foregroundColor(MacPulseColors.appleOrange)
                        Text("\(Int(temp))°C Normal")
                            .font(MacPulseTypography.captionSemibold)
                            .foregroundColor(MacPulseColors.textPrimary)
                    }
                    Spacer()
                    HStack(spacing: MacPulseSpacing.xs) {
                        Image(systemName: sys.battery.isCharging ? "bolt.fill" : "battery.100")
                            .font(.system(size: 9))
                            .foregroundColor(sys.battery.isCharging ? MacPulseColors.appleGreen : MacPulseColors.textSecondary)
                        Text("\(sys.battery.percentage)% • \(sys.battery.isPluggedIn ? "Power Adapter" : "Battery")")
                            .font(MacPulseTypography.caption2)
                            .foregroundColor(MacPulseColors.textSecondary)
                    }
                }
                .padding(.horizontal, MacPulseSpacing.lg)
                .padding(.vertical, 7)
            }
        }
    }
    
    // MARK: - Right Top Consumers Column
    private var topConsumersColumn: some View {
        IslandCard(cornerRadius: MacPulseRadius.card) {
            VStack(alignment: .leading, spacing: MacPulseSpacing.xs) {
                HStack {
                    Text("TOP CONSUMERS")
                        .font(MacPulseTypography.caption2Bold)
                        .foregroundColor(MacPulseColors.textTertiary)
                    Spacer()
                    Button {
                        sys.fetchTopProcesses(limit: 3)
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(MacPulseTypography.caption2Bold)
                            .foregroundColor(MacPulseColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MacPulseSpacing.xs)
                .padding(.top, MacPulseSpacing.xxs)
                
                if sys.topProcesses.isEmpty {
                    VStack {
                        Spacer()
                        Text("Analyzing apps...")
                            .font(MacPulseTypography.caption)
                            .foregroundColor(MacPulseColors.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 3) {
                        ForEach(sys.topProcesses) { proc in
                            processRow(for: proc)
                        }
                    }
                }
            }
            .padding(MacPulseSpacing.sm)
        }
    }
    
    private func processRow(for proc: TopProcessItem) -> some View {
        HStack(spacing: 5) {
            if let img = proc.icon {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: MacPulseDimensions.iconSmall, height: MacPulseDimensions.iconSmall)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 11))
                    .foregroundColor(MacPulseColors.textTertiary)
                    .frame(width: MacPulseDimensions.iconSmall, height: MacPulseDimensions.iconSmall)
            }
            
            Text(proc.name)
                .font(MacPulseTypography.captionSemibold)
                .foregroundColor(MacPulseColors.textPrimary)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            Text(String(format: "%.0f%%", proc.cpuPercentage))
                .font(MacPulseTypography.metricMono)
                .foregroundColor(MacPulseColors.appleCyan)
            
            Text(proc.memoryString)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(MacPulseColors.textTertiary)
        }
        .padding(.vertical, 1.5)
        .padding(.horizontal, MacPulseSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MacPulseRadius.xs, style: .continuous)
                .fill(MacPulseColors.pillBackground)
        )
    }
}
