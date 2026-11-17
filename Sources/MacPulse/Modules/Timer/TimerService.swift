import Foundation
import Combine

public final class TimerService: ObservableObject {
    public static let shared = TimerService()
    
    // MARK: - Active Sub-Tab
    @Published public var activeTab: TimerTab = .pomodoro
    
    // MARK: - 1. Stopwatch State
    @Published public private(set) var stopwatchState: TimerState = .idle
    @Published public private(set) var stopwatchElapsed: TimeInterval = 0.0
    @Published public private(set) var stopwatchLaps: [StopwatchLap] = []
    
    private var stopwatchTimer: Timer?
    private var stopwatchStartTime: Date?
    private var stopwatchAccumulated: TimeInterval = 0.0
    private var lastLapTimestamp: TimeInterval = 0.0
    
    // MARK: - 2. Countdown Timer State
    @Published public private(set) var countdownState: TimerState = .idle
    @Published public var countdownDuration: TimeInterval = 15 * 60 // default 15 min
    @Published public private(set) var countdownRemaining: TimeInterval = 15 * 60
    
    private var countdownTimer: Timer?
    private var countdownEndTime: Date?
    
    // MARK: - 3. Pomodoro Timer State
    @Published public private(set) var pomodoroState: TimerState = .idle
    @Published public private(set) var pomodoroMode: PomodoroMode = .focus
    @Published public private(set) var pomodoroRemaining: TimeInterval = 25 * 60
    @Published public private(set) var pomodoroDuration: TimeInterval = 25 * 60
    @Published public private(set) var completedPomodoros: Int = 0
    @Published public var autoAdvancePomodoro: Bool = false
    
    private var pomodoroTimer: Timer?
    private var pomodoroEndTime: Date?
    
    private init() {}
    
    // MARK: - Stopwatch Actions
    public func startStopwatch() {
        guard stopwatchState != .running else { return }
        stopwatchState = .running
        stopwatchStartTime = Date()
        
        stopwatchTimer?.invalidate()
        stopwatchTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.stopwatchStartTime else { return }
            self.stopwatchElapsed = self.stopwatchAccumulated + Date().timeIntervalSince(start)
        }
    }
    
    public func pauseStopwatch() {
        guard stopwatchState == .running else { return }
        stopwatchState = .paused
        if let start = stopwatchStartTime {
            stopwatchAccumulated += Date().timeIntervalSince(start)
        }
        stopwatchElapsed = stopwatchAccumulated
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
    }
    
    public func resetStopwatch() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
        stopwatchState = .idle
        stopwatchElapsed = 0.0
        stopwatchAccumulated = 0.0
        stopwatchStartTime = nil
        lastLapTimestamp = 0.0
        stopwatchLaps.removeAll()
    }
    
    public func recordLap() {
        guard stopwatchState == .running || stopwatchState == .paused else { return }
        let currentTotal = stopwatchElapsed
        let lapTime = currentTotal - lastLapTimestamp
        lastLapTimestamp = currentTotal
        
        let lap = StopwatchLap(
            lapNumber: stopwatchLaps.count + 1,
            lapTime: lapTime,
            splitTime: currentTotal
        )
        stopwatchLaps.insert(lap, at: 0) // newest on top
    }
    
    // MARK: - Countdown Actions
    public func setCountdownPreset(seconds: TimeInterval) {
        pauseCountdown()
        countdownDuration = seconds
        countdownRemaining = seconds
        countdownState = .idle
    }
    
    public func startCountdown() {
        guard countdownRemaining > 0 else { return }
        countdownState = .running
        countdownEndTime = Date().addingTimeInterval(countdownRemaining)
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let end = self.countdownEndTime else { return }
            let remaining = end.timeIntervalSince(Date())
            if remaining <= 0 {
                self.countdownRemaining = 0
                self.countdownState = .completed
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                
                NotificationManager.shared.sendNotification(
                    title: "Timer Completed",
                    body: "Your countdown timer has finished!",
                    soundName: "Glass"
                )
            } else {
                self.countdownRemaining = remaining
            }
        }
    }
    
    public func pauseCountdown() {
        guard countdownState == .running else { return }
        countdownState = .paused
        if let end = countdownEndTime {
            countdownRemaining = max(0, end.timeIntervalSince(Date()))
        }
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    public func resetCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownState = .idle
        countdownRemaining = countdownDuration
    }
    
    // MARK: - Pomodoro Actions
    public func startPomodoro() {
        guard pomodoroRemaining > 0 else { return }
        pomodoroState = .running
        pomodoroEndTime = Date().addingTimeInterval(pomodoroRemaining)
        
        pomodoroTimer?.invalidate()
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self, let end = self.pomodoroEndTime else { return }
            let remaining = end.timeIntervalSince(Date())
            if remaining <= 0 {
                self.pomodoroRemaining = 0
                self.pomodoroState = .completed
                self.pomodoroTimer?.invalidate()
                self.pomodoroTimer = nil
                self.handlePomodoroCompletion()
            } else {
                self.pomodoroRemaining = remaining
            }
        }
    }
    
    public func pausePomodoro() {
        guard pomodoroState == .running else { return }
        pomodoroState = .paused
        if let end = pomodoroEndTime {
            pomodoroRemaining = max(0, end.timeIntervalSince(Date()))
        }
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
    }
    
    public func resetPomodoro() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroState = .idle
        pomodoroRemaining = pomodoroMode.defaultDuration
        pomodoroDuration = pomodoroMode.defaultDuration
    }
    
    public func switchPomodoroMode(to mode: PomodoroMode) {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroMode = mode
        pomodoroDuration = mode.defaultDuration
        pomodoroRemaining = mode.defaultDuration
        pomodoroState = .idle
    }
    
    public func skipPomodoro() {
        advancePomodoroMode()
    }
    
    private func handlePomodoroCompletion() {
        if pomodoroMode == .focus {
            completedPomodoros += 1
            NotificationManager.shared.sendNotification(
                title: "Focus Session Finished! 🍅",
                body: "Great job! Time for a well-deserved break.",
                soundName: "Glass"
            )
        } else {
            NotificationManager.shared.sendNotification(
                title: "Break Time Over! ⚡️",
                body: "Ready to focus on your next session?",
                soundName: "Glass"
            )
        }
        
        if autoAdvancePomodoro {
            advancePomodoroMode()
            startPomodoro()
        }
    }
    
    private func advancePomodoroMode() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroState = .idle
        
        if pomodoroMode == .focus {
            if completedPomodoros % 4 == 0 && completedPomodoros > 0 {
                switchPomodoroMode(to: .longBreak)
            } else {
                switchPomodoroMode(to: .shortBreak)
            }
        } else {
            switchPomodoroMode(to: .focus)
        }
    }
}
