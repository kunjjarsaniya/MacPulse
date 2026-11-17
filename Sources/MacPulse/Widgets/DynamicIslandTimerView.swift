import AppKit
import SwiftUI

public struct DynamicIslandTimerView: View {
    @ObservedObject private var timer = TimerService.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    @State private var selectedPresetMinutes: Int = 25
    
    public init() {}
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
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
        HStack(spacing: 12) {
            modeSelectorView
            counterDisplayView
            actionControlsView
        }
        .padding(10)
        .frame(height: 118)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.05)))
    }
    
    private var modeSelectorView: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(TimerTab.allCases, id: \.self) { tab in
                Button {
                    timer.activeTab = tab
                    playSoftHaptic()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                        Text(tab.rawValue)
                    }
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(timer.activeTab == tab ? Color(hex: "#38BDF8") : Color.white.opacity(0.55))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(timer.activeTab == tab ? Color(hex: "#38BDF8").opacity(0.15) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 90)
    }
    
    private var counterDisplayView: some View {
        VStack(spacing: 4) {
            Text(currentTimerDisplayTime)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                quickPresetButton("5m", 5)
                quickPresetButton("15m", 15)
                quickPresetButton("25m", 25)
                quickPresetButton("45m", 45)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionControlsView: some View {
        VStack(spacing: 6) {
            Button {
                toggleTimerAction()
                playSoftHaptic()
            } label: {
                Text(isTimerCurrentlyRunning ? "Pause" : "Start")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isTimerCurrentlyRunning ? Color(hex: "#FFD60A") : Color(hex: "#30D158")))
            }
            .buttonStyle(.plain)
            
            Button("Reset") {
                resetTimerAction()
                playSoftHaptic()
            }
            .font(.system(size: 9))
            .foregroundColor(Color.white.opacity(0.50))
            .buttonStyle(.plain)
        }
        .frame(width: 70)
    }
    
    private func quickPresetButton(_ label: String, _ mins: Int) -> some View {
        Button {
            setTimerDuration(mins)
            playSoftHaptic()
        } label: {
            Text(label)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundColor(selectedPresetMinutes == mins ? Color(hex: "#38BDF8") : Color.white.opacity(0.55))
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(selectedPresetMinutes == mins ? Color(hex: "#38BDF8").opacity(0.18) : Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}
