import AppKit
import SwiftUI

// MARK: - Dynamic Island Stats View (Hardware Telemetry & Top Process Consumers)

public struct DynamicIslandStatsView: View {
    @ObservedObject private var sys = SystemMonitorService.shared
    @ObservedObject private var net = NetworkMonitorService.shared
    
    private let refreshTimer = Foundation.Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: MacPulseSpacing.md) {
            hardwareVitalsCard
                .frame(maxWidth: .infinity)
                .frame(height: MacPulseDimensions.contentHeight)
            
            topProcessesCard
                .frame(width: 220, height: MacPulseDimensions.contentHeight)
        }
        .frame(height: MacPulseDimensions.contentHeight)
        .onAppear {
            sys.fetchTopProcesses(limit: 3)
        }
        .onReceive(refreshTimer) { _ in
            sys.fetchTopProcesses(limit: 3)
        }
    }
    
    // MARK: - Left Hardware Vitals Card (Unified Telemetry & Hardware Strip)
    private var hardwareVitalsCard: some View {
        IslandCard(cornerRadius: MacPulseRadius.card) {
            VStack(spacing: 6) {
                // Top Row: CPU & RAM Dual Gauges
                HStack(spacing: MacPulseSpacing.sm) {
                    cpuGaugeTile
                    
                    // Vertical Separator Hairline
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 1)
                        .padding(.vertical, 2)
                    
                    ramGaugeTile
                }
                .frame(maxHeight: .infinity)
                
                // Horizontal Separator Hairline
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                
                // Bottom Strip: Thermals • Battery • Network Speed
                hardwareStatusStrip
                    .frame(height: 16)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - CPU Gauge Block
    private var cpuGaugeTile: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(MacPulseColors.textSecondary)
                
                Text("PROCESSOR")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(MacPulseColors.textTertiary)
                
                Spacer()
                
                Text("\(sys.cpu.coreCount) CORES")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.38))
            }
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(sys.cpu.usagePercentage))")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(MacPulseColors.textPrimary)
                
                Text("%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                
                Text("LOAD")
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.leading, 2)
            }
            
            // Live Mini Waveform Graph (30-sample sliding window)
            MiniTelemetryGraph(
                data: sys.cpuHistory,
                strokeColor: Color.white.opacity(0.85),
                fillColor: Color.white.opacity(0.18)
            )
            .frame(height: 18)
            
            // Micro Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 2.5)
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: max(2.5, geo.size.width * CGFloat(min(sys.cpu.usagePercentage / 100.0, 1.0))), height: 2.5)
                }
            }
            .frame(height: 2.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - RAM Gauge Block
    private var ramGaugeTile: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(MacPulseColors.textSecondary)
                
                Text("UNIFIED RAM")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(MacPulseColors.textTertiary)
                
                Spacer()
                
                let usedGB = Double(sys.ram.usedBytes) / 1_073_741_824.0
                let totalGB = Double(sys.ram.totalBytes) / 1_073_741_824.0
                Text(String(format: "%.1f/%.0fGB", usedGB, totalGB))
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.38))
            }
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(sys.ram.usagePercentage))")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(MacPulseColors.textPrimary)
                
                Text("%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
                
                Text("USED")
                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(Color.white.opacity(0.35))
                    .padding(.leading, 2)
            }
            
            // Live Mini Waveform Graph (30-sample sliding window)
            MiniTelemetryGraph(
                data: sys.ramHistory,
                strokeColor: Color.white.opacity(0.65),
                fillColor: Color.white.opacity(0.12)
            )
            .frame(height: 18)
            
            // Micro Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 2.5)
                    Capsule()
                        .fill(Color.white.opacity(0.60))
                        .frame(width: max(2.5, geo.size.width * CGFloat(min(sys.ram.usagePercentage / 100.0, 1.0))), height: 2.5)
                }
            }
            .frame(height: 2.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Hardware Status Strip (Thermals, Battery, Live Speed)
    private var hardwareStatusStrip: some View {
        HStack(spacing: 0) {
            // 1. Thermals
            let temp = sys.battery.temperatureCelsius > 0 ? sys.battery.temperatureCelsius : 20.0
            HStack(spacing: 3) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 8))
                    .foregroundColor(Color.white.opacity(0.60))
                Text("\(Int(temp))°C")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(MacPulseColors.textPrimary)
                Text("Normal")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.40))
            }
            
            Spacer()
            
            // Separator Dot
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 2, height: 2)
            
            Spacer()
            
            // 2. Battery / Power
            HStack(spacing: 3) {
                Image(systemName: sys.battery.isCharging ? "bolt.fill" : (sys.battery.isPluggedIn ? "powerplug.fill" : "battery.75"))
                    .font(.system(size: 8))
                    .foregroundColor(Color.white.opacity(0.60))
                Text("\(sys.battery.percentage)%")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(MacPulseColors.textPrimary)
                Text(sys.battery.isPluggedIn ? "AC Power" : "Battery")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.40))
            }
            
            Spacer()
            
            // Separator Dot
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 2, height: 2)
            
            Spacer()
            
            // 3. Network Speed
            let down = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
            HStack(spacing: 2.5) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.60))
                Text("\(down.value) \(down.unit)")
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(MacPulseColors.textPrimary)
            }
        }
    }
    
    // MARK: - Right Top Processes Card
    private var topProcessesCard: some View {
        IslandCard(cornerRadius: MacPulseRadius.card) {
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(MacPulseColors.textSecondary)
                    
                    Text("TOP PROCESSES")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .tracking(0.5)
                        .foregroundColor(MacPulseColors.textTertiary)
                    
                    Spacer()
                    
                    Button {
                        sys.fetchTopProcesses(limit: 3)
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.45))
                            .frame(width: 15, height: 15)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                
                // Process Rows
                if sys.topProcesses.isEmpty {
                    VStack(spacing: 4) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.55)
                            .colorInvert()
                        Text("Sampling activity...")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(MacPulseColors.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 3.5) {
                        ForEach(sys.topProcesses) { proc in
                            processRow(for: proc)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
    
    private func processRow(for proc: TopProcessItem) -> some View {
        ZStack(alignment: .leading) {
            // Proportional Background Usage Bar
            GeometryReader { geo in
                let loadRatio = CGFloat(min(max(proc.cpuPercentage / 100.0, 0.0), 1.0))
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: max(0, geo.size.width * loadRatio))
            }
            
            // Content Row
            HStack(spacing: 5) {
                // App Icon
                if let img = proc.icon {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                } else {
                    Image(systemName: "cpu")
                        .font(.system(size: 8))
                        .foregroundColor(Color.white.opacity(0.50))
                        .frame(width: 15, height: 15)
                        .background(
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                
                // Process Name
                Text(proc.name)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(MacPulseColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer(minLength: 4)
                
                // CPU Percentage
                Text(String(format: "%.0f%%", proc.cpuPercentage))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(proc.cpuPercentage > 30 ? .white : Color.white.opacity(0.85))
                
                // Memory Badge
                Text(proc.memoryString)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(Color.white.opacity(0.45))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.07))
                    )
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 23)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Mini Telemetry Waveform Graph (Pure SwiftUI Quadratic Bezier)

private struct MiniTelemetryGraph: View {
    let data: [Double]
    let strokeColor: Color
    let fillColor: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = data.count
            
            if count > 1 {
                let maxVal = max(data.max() ?? 100.0, 1.0)
                let stepX = w / CGFloat(count - 1)
                
                let points: [CGPoint] = data.enumerated().map { i, val in
                    let clamped = max(0.0, min(val, maxVal))
                    let ratio = CGFloat(clamped / maxVal)
                    let x = CGFloat(i) * stepX
                    let y = h - (ratio * (h * 0.82) + (h * 0.08))
                    return CGPoint(x: x, y: y)
                }
                
                ZStack {
                    // Smooth Area Fill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        path.addLine(to: points[0])
                        for i in 1..<points.count {
                            let p0 = points[i - 1]
                            let p1 = points[i]
                            let mid = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                            path.addQuadCurve(to: mid, control: p0)
                        }
                        if let last = points.last {
                            path.addLine(to: last)
                            path.addLine(to: CGPoint(x: last.x, y: h))
                            path.closeSubpath()
                        }
                    }
                    .fill(
                        LinearGradient(
                            colors: [fillColor, fillColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Smooth Stroke Curve
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let p0 = points[i - 1]
                            let p1 = points[i]
                            let mid = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
                            path.addQuadCurve(to: mid, control: p0)
                        }
                        if let last = points.last {
                            path.addLine(to: last)
                        }
                    }
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }
}
