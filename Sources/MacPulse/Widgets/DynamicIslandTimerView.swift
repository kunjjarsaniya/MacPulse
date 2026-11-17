import AppKit
import SwiftUI

// MARK: - Dynamic Island Timer View (Apple-Grade Repeating Reminder, Countdown, Focus & Stopwatch)

public struct DynamicIslandTimerView: View {
    @ObservedObject private var timer = TimerService.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    @State private var reminderMinutes: Int = 5
    @State private var selectedMinutes: Int = 25
    
    public init() {}
    
    private var isRunning: Bool {
        switch timer.activeTab {
        case .reminder: return timer.reminderState == .running
        case .countdown: return timer.countdownState == .running
        case .pomodoro: return timer.pomodoroState == .running
        case .stopwatch: return timer.stopwatchState == .running
        }
    }
    
    private var isPaused: Bool {
        switch timer.activeTab {
        case .reminder: return timer.reminderState == .paused
        case .countdown: return timer.countdownState == .paused
        case .pomodoro: return timer.pomodoroState == .paused
        case .stopwatch: return timer.stopwatchState == .paused
        }
    }
    
    private var displayTimeString: String {
        switch timer.activeTab {
        case .reminder:
            if isRunning || isPaused {
                let mins = Int(timer.reminderRemaining) / 60
                let secs = Int(timer.reminderRemaining) % 60
                return String(format: "%02d:%02d", mins, secs)
            }
            return String(format: "%02d:00", reminderMinutes)
            
        case .countdown:
            if isRunning || isPaused {
                let mins = Int(timer.countdownRemaining) / 60
                let secs = Int(timer.countdownRemaining) % 60
                return String(format: "%02d:%02d", mins, secs)
            }
            return String(format: "%02d:00", selectedMinutes)
            
        case .pomodoro:
            let mins = Int(timer.pomodoroRemaining) / 60
            let secs = Int(timer.pomodoroRemaining) % 60
            return String(format: "%02d:%02d", mins, secs)
            
        case .stopwatch:
            let total = Int(timer.stopwatchElapsed)
            let mins = total / 60
            let secs = total % 60
            let centis = Int((timer.stopwatchElapsed.truncatingRemainder(dividingBy: 1)) * 10)
            return String(format: "%02d:%02d.%d", mins, secs, centis)
        }
    }
    
    private var progressRatio: Double {
        switch timer.activeTab {
        case .reminder:
            guard timer.reminderInterval > 0 else { return 0 }
            if isRunning || isPaused {
                return max(0, min(1.0, 1.0 - (timer.reminderRemaining / timer.reminderInterval)))
            }
            return 0
        case .countdown:
            guard timer.countdownDuration > 0 else { return 0 }
            if isRunning || isPaused {
                return max(0, min(1.0, 1.0 - (timer.countdownRemaining / timer.countdownDuration)))
            }
            return 0
        case .pomodoro:
            guard timer.pomodoroDuration > 0 else { return 0 }
            if isRunning || isPaused {
                return max(0, min(1.0, 1.0 - (timer.pomodoroRemaining / timer.pomodoroDuration)))
            }
            return 0
        case .stopwatch:
            return min(1.0, timer.stopwatchElapsed.truncatingRemainder(dividingBy: 60) / 60.0)
        }
    }
    
    // Reminder minute stepper adjustment
    private func adjustReminderMinutes(by delta: Int) {
        guard !isRunning else { return }
        let newMins = max(1, min(120, reminderMinutes + delta))
        reminderMinutes = newMins
        timer.setReminderInterval(seconds: TimeInterval(newMins * 60))
        HapticFeedback.playSoft()
    }
    
    private func setReminderPresetMinutes(_ mins: Int) {
        guard !isRunning else { return }
        reminderMinutes = mins
        timer.setReminderInterval(seconds: TimeInterval(mins * 60))
        HapticFeedback.playSoft()
    }
    
    // Countdown minute stepper adjustment
    private func adjustMinutes(by delta: Int) {
        guard !isRunning else { return }
        let newMins = max(1, min(120, selectedMinutes + delta))
        selectedMinutes = newMins
        timer.setCountdownPreset(seconds: TimeInterval(newMins * 60))
        HapticFeedback.playSoft()
    }
    
    private func setPresetMinutes(_ mins: Int) {
        guard !isRunning else { return }
        selectedMinutes = mins
        timer.setCountdownPreset(seconds: TimeInterval(mins * 60))
        HapticFeedback.playSoft()
    }
    
    private func toggleStartPause() {
        HapticFeedback.playSoft()
        switch timer.activeTab {
        case .reminder:
            if timer.reminderState == .running {
                timer.pauseReminder()
            } else {
                if timer.reminderInterval != TimeInterval(reminderMinutes * 60) && timer.reminderState == .idle {
                    timer.setReminderInterval(seconds: TimeInterval(reminderMinutes * 60))
                }
                timer.startReminder()
            }
        case .countdown:
            if timer.countdownState == .running {
                timer.pauseCountdown()
            } else {
                if timer.countdownDuration != TimeInterval(selectedMinutes * 60) && timer.countdownState == .idle {
                    timer.setCountdownPreset(seconds: TimeInterval(selectedMinutes * 60))
                }
                timer.startCountdown()
            }
        case .pomodoro:
            if timer.pomodoroState == .running {
                timer.pausePomodoro()
            } else {
                timer.startPomodoro()
            }
        case .stopwatch:
            if timer.stopwatchState == .running {
                timer.pauseStopwatch()
            } else {
                timer.startStopwatch()
            }
        }
    }
    
    private func resetTimer() {
        HapticFeedback.playSoft()
        switch timer.activeTab {
        case .reminder:
            timer.resetReminder()
            timer.setReminderInterval(seconds: TimeInterval(reminderMinutes * 60))
        case .countdown:
            timer.resetCountdown()
            timer.setCountdownPreset(seconds: TimeInterval(selectedMinutes * 60))
        case .pomodoro:
            timer.resetPomodoro()
        case .stopwatch:
            timer.resetStopwatch()
        }
    }
    
    public var body: some View {
        IslandCard(cornerRadius: MacPulseRadius.card) {
            HStack(spacing: MacPulseSpacing.md) {
                // Left Column: Timer Mode Switcher & Status
                modeColumn
                    .frame(width: 108)
                
                // Vertical Separator
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 4)
                
                // Center: Big Time Display, Progress Bar & Custom Time Stepper
                centerDisplayColumn
                    .frame(maxWidth: .infinity)
                
                // Vertical Separator
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 4)
                
                // Right Column: Start / Pause & Reset/Stop Action Buttons
                actionColumn
                    .frame(width: 88)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(height: MacPulseDimensions.contentHeight)
        }
        .onAppear {
            if timer.activeTab == .reminder && timer.reminderState == .idle {
                timer.setReminderInterval(seconds: TimeInterval(reminderMinutes * 60))
            } else if timer.activeTab == .countdown && timer.countdownState == .idle {
                timer.setCountdownPreset(seconds: TimeInterval(selectedMinutes * 60))
            }
        }
    }
    
    // MARK: - 1. Left Mode Switcher Column
    private var modeColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(TimerTab.allCases, id: \.self) { tab in
                Button {
                    timer.activeTab = tab
                    HapticFeedback.playSoft()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 8.5, weight: .semibold))
                            .frame(width: 12)
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: timer.activeTab == tab ? .semibold : .medium, design: .rounded))
                    }
                    .foregroundColor(timer.activeTab == tab ? .white : Color.white.opacity(0.45))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(timer.activeTab == tab ? Color.white.opacity(0.12) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer(minLength: 1)
            
            // Sub-status indicator
            Group {
                if timer.activeTab == .reminder {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 7.5))
                        Text(timer.reminderCycleCount > 0 ? "Cycle #\(timer.reminderCycleCount + 1)" : "Every \(reminderMinutes)m")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.40))
                    .padding(.leading, 6)
                } else if timer.activeTab == .countdown {
                    HStack(spacing: 3) {
                        Image(systemName: timer.countdownRepeating ? "repeat" : "bell.fill")
                            .font(.system(size: 7.5))
                        Text(timer.countdownRepeating ? "Loop every \(selectedMinutes)m" : "Alert on finish")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.40))
                    .padding(.leading, 6)
                } else if timer.activeTab == .pomodoro {
                    HStack(spacing: 3) {
                        Image(systemName: timer.pomodoroMode == .focus ? "brain.head.profile" : "cup.and.saucer.fill")
                            .font(.system(size: 7.5))
                        Text(timer.pomodoroMode == .focus ? "Focus (\(timer.completedPomodoros))" : "Break")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.40))
                    .padding(.leading, 6)
                } else {
                    Text("\(timer.stopwatchLaps.count) Laps")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.40))
                        .padding(.leading, 6)
                }
            }
        }
    }
    
    // MARK: - 2. Center Display Column (Time, Progress Bar & Stepper Presets)
    private var centerDisplayColumn: some View {
        VStack(spacing: 4) {
            // Big Monospaced Rounded Digits
            Text(displayTimeString)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(MacPulseColors.textPrimary)
                .shadow(color: Color.white.opacity(isRunning ? 0.15 : 0.0), radius: 8)
            
            // Live Progress Bar Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.65)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(3, geo.size.width * CGFloat(progressRatio)), height: 3)
                        .animation(.linear(duration: 0.15), value: progressRatio)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 8)
            
            // Stepper & Presets (Reminder, Countdown or Pomodoro Mode)
            if timer.activeTab == .reminder {
                HStack(spacing: 3) {
                    // Minus 1 Minute
                    Button {
                        adjustReminderMinutes(by: -1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isRunning ? Color.white.opacity(0.2) : Color.white.opacity(0.7))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                    
                    // Quick Presets
                    reminderPresetPill("1m", 1)
                    reminderPresetPill("2m", 2)
                    reminderPresetPill("5m", 5)
                    reminderPresetPill("10m", 10)
                    reminderPresetPill("15m", 15)
                    reminderPresetPill("30m", 30)
                    
                    // Plus 1 Minute
                    Button {
                        adjustReminderMinutes(by: 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isRunning ? Color.white.opacity(0.2) : Color.white.opacity(0.7))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                }
                .padding(.top, 2)
            } else if timer.activeTab == .countdown {
                HStack(spacing: 3) {
                    // Minus 1 Minute
                    Button {
                        adjustMinutes(by: -1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isRunning ? Color.white.opacity(0.2) : Color.white.opacity(0.7))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                    
                    // Quick Presets
                    quickPresetPill("1m", 1)
                    quickPresetPill("5m", 5)
                    quickPresetPill("15m", 15)
                    quickPresetPill("25m", 25)
                    quickPresetPill("45m", 45)
                    quickPresetPill("60m", 60)
                    
                    // Plus 1 Minute
                    Button {
                        adjustMinutes(by: 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isRunning ? Color.white.opacity(0.2) : Color.white.opacity(0.7))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                    
                    // Auto-Repeat Toggle
                    Button {
                        timer.countdownRepeating.toggle()
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: "repeat")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(timer.countdownRepeating ? .white : Color.white.opacity(0.35))
                            .frame(width: 18, height: 18)
                            .background(
                                Circle().fill(timer.countdownRepeating ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            } else if timer.activeTab == .pomodoro {
                HStack(spacing: 5) {
                    pomodoroModePill("Focus 25m", .focus)
                    pomodoroModePill("Short 5m", .shortBreak)
                    pomodoroModePill("Long 15m", .longBreak)
                }
                .padding(.top, 2)
            } else {
                // Stopwatch Laps status
                HStack(spacing: 6) {
                    if let firstLap = timer.stopwatchLaps.first {
                        Text("Lap \(firstLap.lapNumber): \(String(format: "%.1fs", firstLap.lapTime))")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.60))
                    } else {
                        Text("Ready to time")
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.40))
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 3. Right Action Column
    private var actionColumn: some View {
        VStack(spacing: 8) {
            // Start / Pause Apple Pill
            Button {
                toggleStartPause()
            } label: {
                Text(isRunning ? "Pause" : (isPaused ? "Resume" : "Start"))
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(isRunning ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(isRunning ? Color.white.opacity(0.18) : Color.white)
                    )
            }
            .buttonStyle(.plain)
            
            // Secondary Actions
            HStack(spacing: 8) {
                if (timer.activeTab == .reminder || (timer.activeTab == .countdown && timer.countdownRepeating)) && (isRunning || isPaused) {
                    Button("Stop") {
                        if timer.activeTab == .reminder {
                            timer.stopReminder()
                        } else {
                            timer.resetCountdown()
                        }
                        HapticFeedback.playSoft()
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .buttonStyle(.plain)
                } else if timer.activeTab == .stopwatch && isRunning {
                    Button("Lap") {
                        timer.recordLap()
                        HapticFeedback.playSoft()
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.70))
                    .buttonStyle(.plain)
                } else {
                    Button("Reset") {
                        resetTimer()
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(MacPulseColors.textTertiary)
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // Reminder Preset Pill
    private func reminderPresetPill(_ label: String, _ mins: Int) -> some View {
        Button {
            setReminderPresetMinutes(mins)
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(reminderMinutes == mins && !isRunning ? .white : Color.white.opacity(0.45))
                .padding(.horizontal, 5.5)
                .padding(.vertical, 2.5)
                .background(
                    Capsule().fill(
                        reminderMinutes == mins && !isRunning
                            ? Color.white.opacity(0.22)
                            : Color.white.opacity(0.06)
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }
    
    // Quick Preset Pill
    private func quickPresetPill(_ label: String, _ mins: Int) -> some View {
        Button {
            setPresetMinutes(mins)
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(selectedMinutes == mins && !isRunning ? .white : Color.white.opacity(0.45))
                .padding(.horizontal, 5.5)
                .padding(.vertical, 2.5)
                .background(
                    Capsule().fill(
                        selectedMinutes == mins && !isRunning
                            ? Color.white.opacity(0.22)
                            : Color.white.opacity(0.06)
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }
    
    // Pomodoro Mode Pill
    private func pomodoroModePill(_ label: String, _ mode: PomodoroMode) -> some View {
        Button {
            timer.switchPomodoroMode(to: mode)
            HapticFeedback.playSoft()
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(timer.pomodoroMode == mode ? .white : Color.white.opacity(0.45))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(
                        timer.pomodoroMode == mode
                            ? Color.white.opacity(0.22)
                            : Color.white.opacity(0.06)
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(isRunning)
    }
}
