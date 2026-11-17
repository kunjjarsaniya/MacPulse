import Foundation
import Combine

public final class TimerService: ObservableObject {
    public static let shared = TimerService()
    
    // MARK: - Active Sub-Tab
    @Published public var activeTab: TimerTab = .reminder
    
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
    @Published public var countdownRepeating: Bool = false
    @Published public private(set) var countdownCycleCount: Int = 0
    
    private var countdownTimer: Timer?
    private var countdownEndTime: Date?
    
    // MARK: - 3. Reminder / Interval Repeating Timer State
    @Published public private(set) var reminderState: TimerState = .idle
    @Published public var reminderInterval: TimeInterval = 5 * 60 // default 5 min interval
    @Published public private(set) var reminderRemaining: TimeInterval = 5 * 60
    @Published public private(set) var reminderCycleCount: Int = 0
    
    private var reminderTimer: Timer?
    private var reminderEndTime: Date?
    
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
                let mins = max(1, Int(round(self.countdownDuration / 60)))
                
                if self.countdownRepeating {
                    self.countdownCycleCount += 1
                    let cycle = self.countdownCycleCount
                    
                    NotificationManager.shared.sendNotification(
                        title: "Timer Completed! ⏰",
                        body: "\(mins)m timer finished (Cycle #\(cycle)) • Repeating...",
                        soundName: "Glass"
                    )
                    
                    Task { @MainActor in
                        DynamicIslandController.shared.triggerAlert(
                            icon: "repeat",
                            title: "Timer Completed! ⏰",
                            subtitle: "\(mins)m timer (Cycle #\(cycle)) • Repeating...",
                            actionTitle: "Stop",
                            soundName: "Glass"
                        ) {
                            TimerService.shared.resetCountdown()
                        }
                    }
                    
                    // Automatically restart countdown loop
                    self.countdownRemaining = self.countdownDuration
                    self.countdownEndTime = Date().addingTimeInterval(self.countdownDuration)
                } else {
                    self.countdownRemaining = 0
                    self.countdownState = .completed
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    
                    NotificationManager.shared.sendNotification(
                        title: "Timer Completed! ⏰",
                        body: "\(mins)m countdown timer has finished.",
                        soundName: "Glass"
                    )
                    
                    Task { @MainActor in
                        DynamicIslandController.shared.triggerAlert(
                            icon: "timer",
                            title: "Timer Completed! ⏰",
                            subtitle: "\(mins)m countdown has finished.",
                            actionTitle: "Repeat",
                            soundName: "Glass"
                        ) {
                            TimerService.shared.resetCountdown()
                            TimerService.shared.startCountdown()
                        }
                    }
                }
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
        countdownCycleCount = 0
    }
    
    // MARK: - 3. Reminder / Repeating Interval Actions
    public func setReminderInterval(seconds: TimeInterval) {
        pauseReminder()
        reminderInterval = seconds
        reminderRemaining = seconds
        reminderState = .idle
        reminderCycleCount = 0
    }
    
    public func startReminder() {
        guard reminderInterval > 0 else { return }
        if reminderState == .idle || reminderRemaining <= 0 {
            reminderRemaining = reminderInterval
        }
        reminderState = .running
        reminderEndTime = Date().addingTimeInterval(reminderRemaining)
        
        reminderTimer?.invalidate()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let end = self.reminderEndTime else { return }
            let remaining = end.timeIntervalSince(Date())
            if remaining <= 0 {
                // Completed one interval!
                self.reminderCycleCount += 1
                let completedCycle = self.reminderCycleCount
                let mins = max(1, Int(round(self.reminderInterval / 60)))
                
                // 1. Send system sound & notification
                NotificationManager.shared.sendNotification(
                    title: "Reminder Alert! ⏰",
                    body: "\(mins)m interval reached (Cycle #\(completedCycle)) • Next in \(mins)m",
                    soundName: "Glass"
                )
                
                // 2. Trigger Dynamic Island Alert HUD with Stop action
                Task { @MainActor in
                    DynamicIslandController.shared.triggerAlert(
                        icon: "clock.arrow.2.circlepath",
                        title: "Reminder Alert! ⏰",
                        subtitle: "\(mins)m interval (Cycle #\(completedCycle)) • Next in \(mins)m",
                        actionTitle: "Stop",
                        soundName: "Glass"
                    ) {
                        TimerService.shared.stopReminder()
                    }
                }
                
                // 3. Immediately restart for next interval without stopping!
                self.reminderRemaining = self.reminderInterval
                self.reminderEndTime = Date().addingTimeInterval(self.reminderInterval)
            } else {
                self.reminderRemaining = remaining
            }
        }
    }
    
    public func pauseReminder() {
        guard reminderState == .running else { return }
        reminderState = .paused
        if let end = reminderEndTime {
            reminderRemaining = max(0, end.timeIntervalSince(Date()))
        }
        reminderTimer?.invalidate()
        reminderTimer = nil
    }
    
    public func stopReminder() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        reminderState = .idle
        reminderRemaining = reminderInterval
        reminderCycleCount = 0
    }
    
    public func resetReminder() {
        stopReminder()
    }
}
