import Foundation

// MARK: - Persistent Data Models

public struct DailyNetworkUsageRecord: Codable, Identifiable {
    public var id: String { dateString } // "YYYY-MM-DD"
    public let dateString: String
    public var bytesReceived: UInt64
    public var bytesSent: UInt64
    public var peakDownloadSpeed: Double // bytes per second
    public var peakUploadSpeed: Double // bytes per second
    
    public init(
        dateString: String,
        bytesReceived: UInt64 = 0,
        bytesSent: UInt64 = 0,
        peakDownloadSpeed: Double = 0,
        peakUploadSpeed: Double = 0
    ) {
        self.dateString = dateString
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.peakDownloadSpeed = peakDownloadSpeed
        self.peakUploadSpeed = peakUploadSpeed
    }
}

public struct UserPreferences: Codable {
    public var launchAtLogin: Bool = false
    public var showInMenuBar: Bool = true
    public var showFloatingWidget: Bool = false
    public var refreshInterval: Double = 1.0 // 1 second
    public var selectedInterface: String = "auto" // auto, en0, en1, all
    public var dailyDataCapGB: Double = 10.0 // optional daily quota alert
    public var soundAlertsEnabled: Bool = true
    public var notificationsEnabled: Bool = true
    public var reminderIntervalMinutes: Int = 5
    
    public init() {}
}

// MARK: - Persistent Storage Manager

public final class StorageManager {
    public static let shared = StorageManager()
    
    private let fileManager = FileManager.default
    private let appSupportDir: URL
    private let historyFileUrl: URL
    private let prefsFileUrl: URL
    
    private let queue = DispatchQueue(label: "com.macpulse.storage", qos: .utility)
    
    private init() {
        let baseDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.appSupportDir = baseDir.appendingPathComponent("MacPulse", isDirectory: true)
        self.historyFileUrl = appSupportDir.appendingPathComponent("network_history.json")
        self.prefsFileUrl = appSupportDir.appendingPathComponent("user_preferences.json")
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Network History
    public func loadHistory() -> [String: DailyNetworkUsageRecord] {
        guard let data = try? Data(contentsOf: historyFileUrl),
              let records = try? JSONDecoder().decode([String: DailyNetworkUsageRecord].self, from: data) else {
            return [:]
        }
        return records
    }
    
    public func saveHistory(_ history: [String: DailyNetworkUsageRecord]) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.createDirectoryIfNeeded()
            if let data = try? JSONEncoder().encode(history) {
                try? data.write(to: self.historyFileUrl, options: .atomic)
            }
        }
    }
    
    // MARK: - User Preferences
    public func loadPreferences() -> UserPreferences {
        guard let data = try? Data(contentsOf: prefsFileUrl),
              let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return UserPreferences()
        }
        return prefs
    }
    
    public func savePreferences(_ prefs: UserPreferences) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.createDirectoryIfNeeded()
            if let data = try? JSONEncoder().encode(prefs) {
                try? data.write(to: self.prefsFileUrl, options: .atomic)
            }
        }
    }
}
