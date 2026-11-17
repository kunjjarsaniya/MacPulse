import SwiftUI

public struct SettingsView: View {
    @Binding public var isPresented: Bool
    
    @State private var launchAtLogin: Bool = false
    @State private var pollInterval: Double = 1.0
    @State private var notificationsEnabled: Bool = true
    @State private var soundAlertsEnabled: Bool = true
    @State private var dailyQuotaGB: Double = 10.0
    
    private let storage = StorageManager.shared
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        GlassCard(interactive: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(MacPulseTheme.accentCyan)
                        Text("MacPulse Preferences")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MacPulseTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider().background(MacPulseTheme.borderSubtle)
                
                VStack(spacing: 14) {
                    // Launch at Login
                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Automatically start background tracking when you log in")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, newValue in
                        _ = LaunchAtLoginManager.shared.setEnabled(newValue)
                        savePrefs()
                    }
                    
                    Divider().background(MacPulseTheme.borderSubtle)
                    
                    // Audio & Notifications
                    Toggle(isOn: $soundAlertsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound Effects")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Play chime upon timer & pomodoro completion")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: soundAlertsEnabled) { _, _ in savePrefs() }
                    
                    Toggle(isOn: $notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Notifications")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Show macOS banner alerts when timers expire")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .onChange(of: notificationsEnabled) { _, _ in savePrefs() }
                    
                    Divider().background(MacPulseTheme.borderSubtle)
                    
                    // Polling Interval
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monitoring Refresh Rate")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Frequency of network & CPU telemetry updates")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                        Spacer()
                        Picker("", selection: $pollInterval) {
                            Text("1.0 sec (Recommended)").tag(1.0)
                            Text("2.0 sec (Low Power)").tag(2.0)
                            Text("5.0 sec (Minimal)").tag(5.0)
                        }
                        .frame(width: 170)
                        .onChange(of: pollInterval) { _, newValue in
                            NetworkMonitorService.shared.startMonitoring(interval: newValue)
                            SystemMonitorService.shared.startMonitoring(interval: newValue)
                            savePrefs()
                        }
                    }
                }
                
                HStack {
                    Spacer()
                    Button("Close") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MacPulseTheme.accentCyan)
                }
            }
        }
        .frame(width: 480)
        .onAppear {
            let p = storage.loadPreferences()
            launchAtLogin = LaunchAtLoginManager.shared.isEnabled || p.launchAtLogin
            soundAlertsEnabled = p.soundAlertsEnabled
            notificationsEnabled = p.notificationsEnabled
            pollInterval = p.refreshInterval
            dailyQuotaGB = p.dailyDataCapGB
        }
    }
    
    private func savePrefs() {
        var p = storage.loadPreferences()
        p.launchAtLogin = launchAtLogin
        p.soundAlertsEnabled = soundAlertsEnabled
        p.notificationsEnabled = notificationsEnabled
        p.refreshInterval = pollInterval
        p.dailyDataCapGB = dailyQuotaGB
        storage.savePreferences(p)
    }
}
