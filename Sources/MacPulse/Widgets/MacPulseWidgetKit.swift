import SwiftUI
import WidgetKit

// MARK: - Native WidgetKit Implementation for macOS Desktop Widgets

public struct MacPulseWidgetEntry: TimelineEntry {
    public let date: Date
    public let downloadSpeed: String
    public let uploadSpeed: String
    public let todayTotal: String
    public let cpuPercentage: Int
    public let ramPercentage: Int
    public let batteryPercentage: Int
    public let pomodoroRemaining: String
    
    public init(
        date: Date = Date(),
        downloadSpeed: String = "2.4 MB/s",
        uploadSpeed: String = "450 KB/s",
        todayTotal: String = "1.8 GB",
        cpuPercentage: Int = 18,
        ramPercentage: Int = 54,
        batteryPercentage: Int = 100,
        pomodoroRemaining: String = "25:00"
    ) {
        self.date = date
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.todayTotal = todayTotal
        self.cpuPercentage = cpuPercentage
        self.ramPercentage = ramPercentage
        self.batteryPercentage = batteryPercentage
        self.pomodoroRemaining = pomodoroRemaining
    }
}

public struct MacPulseTimelineProvider: TimelineProvider {
    public init() {}
    
    public func placeholder(in context: Context) -> MacPulseWidgetEntry {
        MacPulseWidgetEntry()
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (MacPulseWidgetEntry) -> Void) {
        completion(MacPulseWidgetEntry())
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<MacPulseWidgetEntry>) -> Void) {
        let entry = MacPulseWidgetEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views
public struct MacPulseWidgetEntryView: View {
    public var entry: MacPulseWidgetEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: MacPulseWidgetEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            mediumWidgetView
        }
    }
    
    // Compact Small Widget (CPU & Network)
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(MacPulseTheme.accentCyan)
                    .font(.system(size: 14, weight: .bold))
                Text("MacPulse")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(entry.cpuPercentage)%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(MacPulseTheme.accentOrange)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 3) {
                Text("DOWNLOAD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(MacPulseTheme.textTertiary)
                Text(entry.downloadSpeed)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(MacPulseTheme.accentCyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(MacPulseTheme.textTertiary)
                Text(entry.todayTotal)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.09, blue: 0.12)
        }
    }
    
    // Expanded Medium Widget
    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            // Network Column
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .foregroundColor(MacPulseTheme.accentCyan)
                        .font(.system(size: 12, weight: .bold))
                    Text("Network")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 8))
                            .foregroundColor(MacPulseTheme.accentCyan)
                        Text(entry.downloadSpeed)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 8))
                            .foregroundColor(MacPulseTheme.accentPurple)
                        Text(entry.uploadSpeed)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Text("Today: \(entry.todayTotal)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(MacPulseTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().background(Color.white.opacity(0.1))
            
            // System Column
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .foregroundColor(MacPulseTheme.accentOrange)
                        .font(.system(size: 12, weight: .bold))
                    Text("Hardware")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("CPU")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(MacPulseTheme.textTertiary)
                        Text("\(entry.cpuPercentage)%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(MacPulseTheme.accentOrange)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("RAM")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(MacPulseTheme.textTertiary)
                        Text("\(entry.ramPercentage)%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(MacPulseTheme.accentBlue)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 9))
                        .foregroundColor(MacPulseTheme.accentGreen)
                    Text("Focus: \(entry.pomodoroRemaining)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MacPulseTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.09, blue: 0.12)
        }
    }
}
