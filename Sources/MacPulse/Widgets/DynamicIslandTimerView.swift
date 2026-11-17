import AppKit
import SwiftUI

// MARK: - Dynamic Island Timer View (Focus, Countdown & Stopwatch)

public struct DynamicIslandTimerView: View {
    @ObservedObject private var timer = TimerService.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    @State private var selectedPresetMinutes: Int = 25
    
    public init() {}
    
    private var isTimerCurrentlyRunning: Bool {
        switch timer.activeTab {
        case .countdown: return timer.countdownState == .running
        case .pomodoro: return timer.pomodoroState == .running
        case .stopwatch: return timer.stopwatchState == .running
        }
    }
    
    private var currentTimerDisplayTime: String {
        switch timer.activeTab {
        case .countdown:
            if timer.countdownState == .running || timer.countdownState == .paused {
                let mins = Int(timer.countdownRemaining) / 60
                let secs = Int(timer.countdownRemaining) % 60
                return String(format: "%02d:%02d", mins, secs)
            }
            return String(format: "%02d:00", selectedPresetMinutes)
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
    
    private func setTimerDuration(_ mins: Int) {
        selectedPresetMinutes = mins
        timer.setCountdownPreset(seconds: TimeInterval(mins * 60))
        controller.triggerToast(
            title: "\(mins) Minute Timer Set!",
            subtitle: "You'll get a notification in \(mins) minutes."
        )
    }
    
    private func toggleTimerAction() {
        switch timer.activeTab {
        case .countdown:
            if timer.countdownState == .running {
                timer.pauseCountdown()
            } else {
                if timer.countdownDuration != TimeInterval(selectedPresetMinutes * 60) {
                    timer.setCountdownPreset(seconds: TimeInterval(selectedPresetMinutes * 60))
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
    
    private func resetTimerAction() {
        switch timer.activeTab {
        case .countdown:
            timer.resetCountdown()
            timer.setCountdownPreset(seconds: TimeInterval(selectedPresetMinutes * 60))
        case .pomodoro:
            timer.resetPomodoro()
        case .stopwatch:
            timer.resetStopwatch()
        }
    }
    
    public var body: some View {
        IslandCard(cornerRadius: MacPulseRadius.shelf) {
            HStack(spacing: MacPulseSpacing.xl) {
                modeSelectorView
                counterDisplayView
                actionControlsView
            }
            .padding(MacPulseSpacing.lg)
            .frame(height: MacPulseDimensions.contentHeight)
        }
    }
    
    private var modeSelectorView: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(TimerTab.allCases, id: \.self) { tab in
                Button {
                    timer.activeTab = tab
                    HapticFeedback.playSoft()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                        Text(tab.rawValue)
                    }
                    .font(MacPulseTypography.footnoteSemibold)
                    .foregroundColor(timer.activeTab == tab ? MacPulseColors.appleCyan : MacPulseColors.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: MacPulseRadius.sm, style: .continuous)
                            .fill(timer.activeTab == tab ? MacPulseColors.appleCyan.opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 90)
    }
    
    private var counterDisplayView: some View {
        VStack(spacing: MacPulseSpacing.xs) {
            Text(currentTimerDisplayTime)
                .font(MacPulseTypography.timerDisplay)
                .foregroundColor(MacPulseColors.textPrimary)
            
            HStack(spacing: MacPulseSpacing.xs) {
                quickPresetButton("5m", 5)
                quickPresetButton("15m", 15)
                quickPresetButton("25m", 25)
                quickPresetButton("45m", 45)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionControlsView: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            Button {
                toggleTimerAction()
                HapticFeedback.playSoft()
            } label: {
                Text(isTimerCurrentlyRunning ? "Pause" : "Start")
                    .font(MacPulseTypography.subheadline)
                    .foregroundColor(.black)
                    .padding(.horizontal, MacPulseSpacing.gutter)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            isTimerCurrentlyRunning ? MacPulseColors.appleYellow : MacPulseColors.appleGreen
                        )
                    )
            }
            .buttonStyle(.plain)
            
            Button("Reset") {
                resetTimerAction()
                HapticFeedback.playSoft()
            }
            .font(MacPulseTypography.captionSemibold)
            .foregroundColor(MacPulseColors.textTertiary)
            .buttonStyle(.plain)
        }
        .frame(width: 72)
    }
    
    private func quickPresetButton(_ label: String, _ mins: Int) -> some View {
        Button {
            setTimerDuration(mins)
            HapticFeedback.playSoft()
        } label: {
            Text(label)
                .font(MacPulseTypography.captionBold)
                .foregroundColor(selectedPresetMinutes == mins ? MacPulseColors.appleCyan : MacPulseColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule().fill(
                        selectedPresetMinutes == mins ? MacPulseColors.appleCyan.opacity(0.20) : MacPulseColors.pillBackground
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
