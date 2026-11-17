import Foundation

// MARK: - Timer Models

public enum TimerTab: String, CaseIterable, CustomStringConvertible {
    case reminder = "Reminder"
    case countdown = "Countdown"
    case stopwatch = "Stopwatch"
    
    public var description: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .reminder: return "clock.arrow.2.circlepath"
        case .countdown: return "timer"
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

public enum TimerState {
    case idle
    case running
    case paused
    case completed
}
