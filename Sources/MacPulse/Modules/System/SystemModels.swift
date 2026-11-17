import Foundation
import AppKit

// MARK: - Top Process Consumer Model

public struct TopProcessItem: Identifiable, Hashable {
    public let id: Int32
    public let name: String
    public let cpuPercentage: Double
    public let memoryBytes: UInt64
    public let icon: NSImage?
    
    public init(id: Int32, name: String, cpuPercentage: Double, memoryBytes: UInt64, icon: NSImage? = nil) {
        self.id = id
        self.name = name
        self.cpuPercentage = cpuPercentage
        self.memoryBytes = memoryBytes
        self.icon = icon
    }
    
    public var memoryString: String {
        let mb = Double(memoryBytes) / (1024 * 1024)
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - System Telemetry Models

public struct CPUSnapshot {
    public var usagePercentage: Double = 0.0 // 0.0 to 100.0
    public var userPercentage: Double = 0.0
    public var systemPercentage: Double = 0.0
    public var idlePercentage: Double = 100.0
    public var coreCount: Int = 8
    
    public init() {}
}

public struct RAMSnapshot {
    public var totalBytes: UInt64 = 0
    public var usedBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0
    public var activeBytes: UInt64 = 0
    public var wiredBytes: UInt64 = 0
    public var compressedBytes: UInt64 = 0
    
    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    public init() {}
}

public struct DiskSnapshot {
    public var totalBytes: UInt64 = 0
    public var usedBytes: UInt64 = 0
    public var freeBytes: UInt64 = 0
    public var volumeName: String = "Macintosh HD"
    
    public var usagePercentage: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    public init() {}
}

public struct BatterySnapshot {
    public var hasBattery: Bool = false
    public var percentage: Int = 100
    public var isCharging: Bool = false
    public var isPluggedIn: Bool = true
    public var cycleCount: Int = 0
    public var healthPercentage: Int = 100
    public var condition: String = "Normal"
    public var temperatureCelsius: Double = 25.0
    public var timeRemainingMinutes: Int? = nil // nil if calculating or AC
    
    public init() {}
}

public struct UptimeSnapshot {
    public var bootDate: Date = Date()
    public var uptimeSeconds: TimeInterval = 0
    
    public var formattedUptime: String {
        let totalSeconds = Int(uptimeSeconds)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    public init() {}
}
