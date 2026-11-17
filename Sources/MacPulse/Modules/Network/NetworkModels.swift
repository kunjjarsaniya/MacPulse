import Foundation

// MARK: - Network Models

public struct NetworkSpeedSnapshot {
    public let downloadBytesPerSec: Double
    public let uploadBytesPerSec: Double
    public let timestamp: Date
    
    public init(downloadBytesPerSec: Double = 0, uploadBytesPerSec: Double = 0, timestamp: Date = Date()) {
        self.downloadBytesPerSec = downloadBytesPerSec
        self.uploadBytesPerSec = uploadBytesPerSec
        self.timestamp = timestamp
    }
}

public struct NetworkInterfaceInfo: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let isWiFi: Bool
    public let isActive: Bool
    public let ipAddress: String?
    public let macAddress: String?
    
    public init(name: String, displayName: String, isWiFi: Bool, isActive: Bool, ipAddress: String? = nil, macAddress: String? = nil) {
        self.name = name
        self.displayName = displayName
        self.isWiFi = isWiFi
        self.isActive = isActive
        self.ipAddress = ipAddress
        self.macAddress = macAddress
    }
}

public enum NetworkUnitFormatter {
    public static func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        let kb = b / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        let tb = gb / 1024.0
        
        if tb >= 1.0 {
            return String(format: "%.2f TB", tb)
        } else if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
    
    public static func formatSpeed(_ bytesPerSec: Double) -> (value: String, unit: String) {
        let b = max(0, bytesPerSec)
        let kb = b / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        
        if gb >= 1.0 {
            return (String(format: "%.2f", gb), "GB/s")
        } else if mb >= 1.0 {
            return (String(format: "%.2f", mb), "MB/s")
        } else if kb >= 1.0 {
            return (String(format: "%.1f", kb), "KB/s")
        } else {
            return (String(format: "%.0f", b), "B/s")
        }
    }
}
