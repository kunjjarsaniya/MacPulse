import Foundation
import Combine
import AppKit

public final class NetworkHistoryStore: ObservableObject {
    public static let shared = NetworkHistoryStore()
    
    @Published public private(set) var todayDownloadBytes: UInt64 = 0
    @Published public private(set) var todayUploadBytes: UInt64 = 0
    @Published public private(set) var peakDownloadSpeed: Double = 0
    @Published public private(set) var peakUploadSpeed: Double = 0
    @Published public private(set) var allHistory: [DailyNetworkUsageRecord] = []
    
    private var historyMap: [String: DailyNetworkUsageRecord] = [:]
    private var currentDayString: String = ""
    private var lastSaveTime: Date = Date()
    private let storage = StorageManager.shared
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone.current
        return df
    }()
    
    private init() {
        self.currentDayString = dateFormatter.string(from: Date())
        loadFromStorage()
        setupTerminationObserver()
    }
    
    private func setupTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushToDisk()
        }
    }
    
    public func flushToDisk() {
        storage.saveHistory(historyMap)
    }
    
    public var yesterdayTotalBytes: UInt64 {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        let dateStr = dateFormatter.string(from: yesterday)
        guard let rec = historyMap[dateStr] else { return 0 }
        return rec.bytesReceived + rec.bytesSent
    }
    
    public var comparisonVsYesterday: (percentage: Int, isIncrease: Bool)? {
        let yTotal = yesterdayTotalBytes
        let tTotal = todayDownloadBytes + todayUploadBytes
        guard yTotal > 0 else { return nil }
        let diff = Double(Int64(tTotal) - Int64(yTotal))
        let percent = Int(round((diff / Double(yTotal)) * 100.0))
        return (abs(percent), percent >= 0)
    }
    
    private func loadFromStorage() {
        historyMap = storage.loadHistory()
        checkDateRollover(now: Date())
        
        if let today = historyMap[currentDayString] {
            todayDownloadBytes = today.bytesReceived
            todayUploadBytes = today.bytesSent
            peakDownloadSpeed = today.peakDownloadSpeed
            peakUploadSpeed = today.peakUploadSpeed
        } else {
            let record = DailyNetworkUsageRecord(dateString: currentDayString)
            historyMap[currentDayString] = record
            todayDownloadBytes = 0
            todayUploadBytes = 0
            peakDownloadSpeed = 0
            peakUploadSpeed = 0
            storage.saveHistory(historyMap)
        }
        
        refreshHistoryList()
    }
    
    public func addUsage(downloadDelta: UInt64, uploadDelta: UInt64, currentDownloadSpeed: Double, currentUploadSpeed: Double) {
        let now = Date()
        checkDateRollover(now: now)
        
        todayDownloadBytes += downloadDelta
        todayUploadBytes += uploadDelta
        
        if currentDownloadSpeed > peakDownloadSpeed {
            peakDownloadSpeed = currentDownloadSpeed
        }
        if currentUploadSpeed > peakUploadSpeed {
            peakUploadSpeed = currentUploadSpeed
        }
        
        var record = historyMap[currentDayString] ?? DailyNetworkUsageRecord(dateString: currentDayString)
        record.bytesReceived = todayDownloadBytes
        record.bytesSent = todayUploadBytes
        record.peakDownloadSpeed = peakDownloadSpeed
        record.peakUploadSpeed = peakUploadSpeed
        historyMap[currentDayString] = record
        
        // Debounce disk writes to once every 30 seconds to minimize I/O overhead
        if now.timeIntervalSince(lastSaveTime) >= 30.0 {
            lastSaveTime = now
            storage.saveHistory(historyMap)
        }
        
        refreshHistoryList()
    }
    
    public func checkDateRollover(now: Date = Date()) {
        let todayStr = dateFormatter.string(from: now)
        if todayStr != currentDayString {
            // Day has changed (midnight crossed)
            currentDayString = todayStr
            if let existing = historyMap[todayStr] {
                todayDownloadBytes = existing.bytesReceived
                todayUploadBytes = existing.bytesSent
                peakDownloadSpeed = existing.peakDownloadSpeed
                peakUploadSpeed = existing.peakUploadSpeed
            } else {
                todayDownloadBytes = 0
                todayUploadBytes = 0
                peakDownloadSpeed = 0
                peakUploadSpeed = 0
                let record = DailyNetworkUsageRecord(dateString: todayStr)
                historyMap[todayStr] = record
                storage.saveHistory(historyMap)
            }
            refreshHistoryList()
        }
    }
    
    private func refreshHistoryList() {
        let sorted = historyMap.values.sorted { $0.dateString > $1.dateString }
        DispatchQueue.main.async {
            self.allHistory = sorted
        }
    }
    
    public func getPastDays(count: Int) -> [DailyNetworkUsageRecord] {
        let calendar = Calendar.current
        var result: [DailyNetworkUsageRecord] = []
        let today = Date()
        
        for i in (0..<count).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateStr = dateFormatter.string(from: date)
                if let rec = historyMap[dateStr] {
                    result.append(rec)
                } else {
                    result.append(DailyNetworkUsageRecord(dateString: dateStr, bytesReceived: 0, bytesSent: 0))
                }
            }
        }
        return result
    }
    
    public func resetToday() {
        todayDownloadBytes = 0
        todayUploadBytes = 0
        peakDownloadSpeed = 0
        peakUploadSpeed = 0
        var record = historyMap[currentDayString] ?? DailyNetworkUsageRecord(dateString: currentDayString)
        record.bytesReceived = 0
        record.bytesSent = 0
        record.peakDownloadSpeed = 0
        record.peakUploadSpeed = 0
        historyMap[currentDayString] = record
        storage.saveHistory(historyMap)
        refreshHistoryList()
    }
}
