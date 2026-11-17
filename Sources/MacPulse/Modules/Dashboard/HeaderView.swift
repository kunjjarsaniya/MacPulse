import SwiftUI

public struct HeaderView: View {
    @ObservedObject private var net = NetworkMonitorService.shared
    @ObservedObject private var sys = SystemMonitorService.shared
    @Binding public var showSettings: Bool
    public let onToggleWidget: () -> Void
    
    @State private var isPulsing = false
    
    public init(showSettings: Binding<Bool>, onToggleWidget: @escaping () -> Void) {
        self._showSettings = showSettings
        self.onToggleWidget = onToggleWidget
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // App Branding
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MacPulseTheme.accentCyan, MacPulseTheme.accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: MacPulseTheme.accentCyan.opacity(0.5), radius: isPulsing ? 8 : 4)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("MacPulse")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("PRO")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(MacPulseTheme.accentCyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(MacPulseTheme.accentCyan.opacity(0.18))
                                    .overlay(Capsule().stroke(MacPulseTheme.accentCyan.opacity(0.4), lineWidth: 0.8))
                            )
                    }
                    Text("Native Dashboard & System Telemetry")
                        .font(.system(size: 11))
                        .foregroundColor(MacPulseTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Live Quick Telemetry Pills
            HStack(spacing: 10) {
                // Network Live Pill
                let down = NetworkUnitFormatter.formatSpeed(net.currentDownloadSpeed)
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MacPulseTheme.accentCyan)
                    Text("\(down.value) \(down.unit)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 9)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(Capsule().stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                )
                
                // CPU Live Pill
                HStack(spacing: 5) {
                    Image(systemName: "cpu")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MacPulseTheme.accentOrange)
                    Text("\(Int(sys.cpu.usagePercentage))% CPU")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 9)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(Capsule().stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                )
                
                // RAM Live Pill
                HStack(spacing: 5) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MacPulseTheme.accentBlue)
                    Text("\(Int(sys.ram.usagePercentage))% RAM")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 9)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .overlay(Capsule().stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                )
            }
            
            // Widget Launchers
            HStack(spacing: 8) {
                // Wi-Fi Widget Button
                Button {
                    WiFiWidgetController.shared.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "wifi")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        Text("Wi-Fi Widget")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .help("Toggle standalone desktop Wi-Fi data widget")
                
                // Dynamic Island Button
                Button {
                    DynamicIslandController.shared.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 14, height: 7)
                        Text("Dynamic Island")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .help("Toggle Apple Dynamic Island for Timers & System Health")
            }
            
            // Settings Button
            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(showSettings ? MacPulseTheme.accentCyan : MacPulseTheme.textSecondary)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(showSettings ? 0.12 : 0.05))
                            .overlay(Circle().stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
            .help("App Preferences & Settings")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Color.black.opacity(0.4)
                .overlay(
                    Rectangle()
                        .fill(MacPulseTheme.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
}
