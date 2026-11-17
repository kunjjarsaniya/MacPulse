import Foundation

// MARK: - Timer Models

public enum TimerTab: String, CaseIterable, CustomStringConvertible {
    case reminder = "Reminder"
    case countdown = "Countdown"
    case pomodoro = "Pomodoro"
    case stopwatch = "Stopwatch"
    
    public var description: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .reminder: return "clock.arrow.2.circlepath"
        case .countdown: return "timer"
        case .pomodoro: return "brain.head.profile"
        case .stopwatch: return "stopwatch"
        }
    }
}

public struct StopwatchLap: Identifiable, Equatable {
    public let id = UUID()
    public let lapNumber: Int
    public let lapTime: TimeInterval
    public let splitTime: TimeInterval
    
    public init(lapNumber: Int, lapTime: TimeInterval, splitTime: TimeInterval) {
        self.lapNumber = lapNumber
        self.lapTime = lapTime
        self.splitTime = splitTime
    }
}

public enum PomodoroMode: String, CaseIterable {
    case focus = "Focus Session"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    public var defaultDuration: TimeInterval {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    public var icon: String {
        switch self {
        case .focus: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
}

public enum TimerState {
    case idle
    case running
    case paused
    case completed
}
