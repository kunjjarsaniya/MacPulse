import AppKit
import SwiftUI

public struct DynamicIslandStatsView: View {
    @ObservedObject private var sys = SystemMonitorService.shared
    
    public init() {}
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            vitalsColumn
                .frame(maxWidth: .infinity)
            
            topConsumersColumn
                .frame(width: 220, height: 118)
        }
        .frame(height: 118)
        .onAppear {
            sys.fetchTopProcesses(limit: 3)
        }
    }
    
    private var vitalsColumn: some View {
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
    }
    
    private var topConsumersColumn: some View {
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
                        processRow(for: proc)
                    }
                }
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
    }
    
    private func processRow(for proc: TopProcessItem) -> some View {
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
