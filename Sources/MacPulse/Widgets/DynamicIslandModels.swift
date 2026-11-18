import Foundation

// MARK: - Dynamic Island Models & Enums

public enum TabTransitionDirection {
    case forward
    case backward
}

public enum MacPulseShelfTab: String, CaseIterable, Identifiable {
    case stats = "Stats"
    case home = "Home"
    case timer = "Timer"
    case clipboard = "Clipboard"
    case notes = "Notes"
    
    public var id: String { rawValue }
    
    public var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
    
    public var icon: String {
        switch self {
        case .stats: return "chart.xyaxis.line"
        case .home: return "house.fill"
        case .timer: return "timer"
        case .clipboard: return "doc.on.clipboard"
        case .notes: return "note.text"
        }
    }
}

public enum DynamicIslandHUDType: String, CaseIterable, Identifiable {
    case volume = "Volume"
    case brightness = "Brightness"
    
    public var id: String { rawValue }
}

public struct DynamicIslandAlertItem: Identifiable, Equatable {
    public let id = UUID()
    public let icon: String
    public let title: String
    public let subtitle: String
    public let actionTitle: String?
    public let soundName: String
    
    public init(
        icon: String = "timer",
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        soundName: String = "Glass"
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.soundName = soundName
    }
    
    public static func == (lhs: DynamicIslandAlertItem, rhs: DynamicIslandAlertItem) -> Bool {
        lhs.id == rhs.id
    }
}
