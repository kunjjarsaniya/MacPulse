import SwiftUI

public struct TimerCard: View {
    @ObservedObject private var timerService = TimerService.shared
    
    public init() {}
    
    public var body: some View {
        GlassCard(interactive: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(MacPulseTheme.accentPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(MacPulseTheme.accentPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Productivity & Focus Timers")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Stopwatch, Countdown & Pomodoro intervals")
                                .font(.system(size: 11))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Tab Picker
                    SegmentedPillPicker(selection: $timerService.activeTab, items: TimerTab.allCases)
                }
                
                Divider().background(MacPulseTheme.borderSubtle)
                
                // Active Subview
                switch timerService.activeTab {
                case .pomodoro:
                    PomodoroView()
                case .countdown:
                    CountdownView()
                case .stopwatch:
                    StopwatchView()
                }
            }
        }
    }
}

// MARK: - 1. Pomodoro View
public struct PomodoroView: View {
    @ObservedObject private var timer = TimerService.shared
    
    public var body: some View {
        VStack(spacing: 20) {
            // Mode Selectors
            HStack(spacing: 8) {
                ForEach(PomodoroMode.allCases, id: \.self) { mode in
                    let isSelected = timer.pomodoroMode == mode
                    Button {
                        timer.switchPomodoroMode(to: mode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11))
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundColor(isSelected ? .white : MacPulseTheme.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? modeColor(mode).opacity(0.3) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isSelected ? modeColor(mode) : MacPulseTheme.borderSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Toggle("Auto-advance", isOn: $timer.autoAdvancePomodoro)
                    .toggleStyle(.switch)
                    .font(.system(size: 11))
                    .foregroundColor(MacPulseTheme.textSecondary)
            }
            
            // Big Circular Timer Display
            let progress = timer.pomodoroDuration > 0 ? (timer.pomodoroDuration - timer.pomodoroRemaining) / timer.pomodoroDuration : 0.0
            
            HStack(spacing: 40) {
                ZStack {
                    CircularProgressView(
                        progress: progress,
                        lineWidth: 12,
                        gradient: timer.pomodoroMode == .focus ? MacPulseTheme.pomodoroGradient : MacPulseTheme.breakGradient,
                        size: 150
                    )
                    
                    VStack(spacing: 4) {
                        Text(formatMinutesSeconds(timer.pomodoroRemaining))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(timer.pomodoroMode.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(modeColor(timer.pomodoroMode))
                    }
                }
                
                // Controls & Session Stats
                VStack(alignment: .leading, spacing: 16) {
                    // Completed sessions tally
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COMPLETED SESSIONS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MacPulseTheme.textTertiary)
                        
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { index in
                                let filled = (timer.completedPomodoros % 4) > index || (timer.completedPomodoros > 0 && timer.completedPomodoros % 4 == 0)
                                Circle()
                                    .fill(filled ? MacPulseTheme.accentRed : Color.white.opacity(0.1))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            Text("(\(timer.completedPomodoros) total)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(MacPulseTheme.textSecondary)
                        }
                    }
                    
                    // Buttons
                    HStack(spacing: 12) {
                        if timer.pomodoroState == .running {
                            ModernActionButton(
                                title: "Pause",
                                icon: "pause.fill",
                                gradient: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) {
                                timer.pausePomodoro()
                            }
                        } else {
                            ModernActionButton(
                                title: timer.pomodoroState == .paused ? "Resume" : "Start Focus",
                                icon: "play.fill",
                                gradient: timer.pomodoroMode == .focus ? MacPulseTheme.pomodoroGradient : MacPulseTheme.breakGradient
                            ) {
                                timer.startPomodoro()
                            }
                        }
                        
                        Button {
                            timer.skipPomodoro()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "forward.fill")
                                Text("Skip")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            timer.resetPomodoro()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(MacPulseTheme.textTertiary)
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }
    
    private func modeColor(_ mode: PomodoroMode) -> Color {
        switch mode {
        case .focus: return MacPulseTheme.accentRed
        case .shortBreak: return MacPulseTheme.accentGreen
        case .longBreak: return MacPulseTheme.accentCyan
        }
    }
    
    private func formatMinutesSeconds(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        let min = s / 60
        let sec = s % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

// MARK: - 2. Countdown View
public struct CountdownView: View {
    @ObservedObject private var timer = TimerService.shared
    
    private let presets: [(label: String, sec: TimeInterval)] = [
        ("1m", 60),
        ("5m", 300),
        ("10m", 600),
        ("15m", 900),
        ("25m", 1500),
        ("30m", 1800),
        ("45m", 2700),
        ("60m", 3600)
    ]
    
    public var body: some View {
        VStack(spacing: 20) {
            // Preset Pills
            HStack(spacing: 8) {
                ForEach(presets, id: \.label) { p in
                    let isCurrent = timer.countdownDuration == p.sec
                    Button {
                        timer.setCountdownPreset(seconds: p.sec)
                    } label: {
                        Text(p.label)
                            .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                            .foregroundColor(isCurrent ? .white : MacPulseTheme.textSecondary)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isCurrent ? MacPulseTheme.accentBlue.opacity(0.35) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isCurrent ? MacPulseTheme.accentBlue : MacPulseTheme.borderSubtle, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            
            // Big Display & Progress
            HStack(spacing: 40) {
                let progress = timer.countdownDuration > 0 ? (timer.countdownDuration - timer.countdownRemaining) / timer.countdownDuration : 0.0
                
                ZStack {
                    CircularProgressView(
                        progress: progress,
                        lineWidth: 12,
                        gradient: MacPulseTheme.downloadGradient,
                        size: 140
                    )
                    
                    VStack(spacing: 2) {
                        Text(formatCountdown(timer.countdownRemaining))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(timer.countdownState == .running ? "REMAINING" : (timer.countdownState == .completed ? "DONE!" : "READY"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(timer.countdownState == .completed ? MacPulseTheme.accentGreen : MacPulseTheme.accentCyan)
                    }
                }
                
                // Controls
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        if timer.countdownState == .running {
                            ModernActionButton(
                                title: "Pause",
                                icon: "pause.fill",
                                gradient: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) {
                                timer.pauseCountdown()
                            }
                        } else {
                            ModernActionButton(
                                title: timer.countdownState == .paused ? "Resume" : "Start Timer",
                                icon: "play.fill",
                                gradient: MacPulseTheme.downloadGradient
                            ) {
                                timer.startCountdown()
                            }
                        }
                        
                        Button {
                            timer.resetCountdown()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Configured duration: \(formatCountdown(timer.countdownDuration))")
                        .font(.system(size: 11))
                        .foregroundColor(MacPulseTheme.textTertiary)
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
        }
    }
    
    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let hrs = total / 3600
        let min = (total % 3600) / 60
        let sec = total % 60
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, min, sec)
        } else {
            return String(format: "%02d:%02d", min, sec)
        }
    }
}

// MARK: - 3. Stopwatch View
public struct StopwatchView: View {
    @ObservedObject private var timer = TimerService.shared
    
    public var body: some View {
        VStack(spacing: 18) {
            // Big Display
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatStopwatch(timer.stopwatchElapsed))
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        if timer.stopwatchState == .running {
                            ModernActionButton(
                                title: "Pause",
                                icon: "pause.fill",
                                gradient: LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                            ) {
                                timer.pauseStopwatch()
                            }
                            
                            ModernActionButton(
                                title: "Lap",
                                icon: "plus.circle.fill",
                                gradient: MacPulseTheme.ramGradient
                            ) {
                                timer.recordLap()
                            }
                        } else {
                            ModernActionButton(
                                title: timer.stopwatchState == .paused ? "Resume" : "Start",
                                icon: "play.fill",
                                gradient: MacPulseTheme.downloadGradient
                            ) {
                                timer.startStopwatch()
                            }
                        }
                        
                        Button {
                            timer.resetStopwatch()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MacPulseTheme.textSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Laps List
                if !timer.stopwatchLaps.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LAPS RECORDED")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MacPulseTheme.textTertiary)
                        
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(timer.stopwatchLaps) { lap in
                                    HStack {
                                        Text("Lap \(lap.lapNumber)")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(MacPulseTheme.textSecondary)
                                        Spacer()
                                        Text(formatLap(lap.lapTime))
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.vertical, 3)
                                    .padding(.horizontal, 8)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.03)))
                                }
                            }
                        }
                        .frame(width: 220, height: 110)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MacPulseTheme.borderSubtle, lineWidth: 1))
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func formatStopwatch(_ seconds: TimeInterval) -> String {
        let totalCenti = Int(seconds * 100)
        let centis = totalCenti % 100
        let totalSec = totalCenti / 100
        let sec = totalSec % 60
        let min = (totalSec / 60) % 60
        let hrs = totalSec / 3600
        
        if hrs > 0 {
            return String(format: "%02d:%02d:%02d.%02d", hrs, min, sec, centis)
        } else {
            return String(format: "%02d:%02d.%02d", min, sec, centis)
        }
    }
    
    private func formatLap(_ seconds: TimeInterval) -> String {
        let totalCenti = Int(seconds * 100)
        let centis = totalCenti % 100
        let totalSec = totalCenti / 100
        let sec = totalSec % 60
        let min = totalSec / 60
        return String(format: "+%02d:%02d.%02d", min, sec, centis)
    }
}
