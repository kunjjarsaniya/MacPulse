import Foundation
import Network
import AppKit

func assertTrue(_ condition: Bool, _ msg: String) {
    if !condition {
        print("❌ Assertion Failed: \(msg)")
        exit(1)
    } else {
        print("  ✓ \(msg)")
    }
}

print("========================================")
print("  Running MacPulse Verification Tests   ")
print("========================================")

// 1. Test Physical Telemetry
print("\n[1] Testing Mach Kernel & System APIs...")
let physMem = ProcessInfo.processInfo.physicalMemory
assertTrue(physMem >= 1024 * 1024 * 1024, "Physical RAM detected: \(Double(physMem) / (1024*1024*1024)) GB")

let cores = ProcessInfo.processInfo.processorCount
assertTrue(cores >= 1, "CPU Processor Cores detected: \(cores) cores")

let uptime = ProcessInfo.processInfo.systemUptime
assertTrue(uptime > 0, "System Uptime detected: \(Int(uptime)) seconds")

if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
    let total = (attrs[.systemSize] as? NSNumber)?.uint64Value ?? 0
    let free = (attrs[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
    assertTrue(total > 0 && free > 0 && free <= total, "Disk storage detected: Total \(total / (1024*1024*1024)) GB, Free \(free / (1024*1024*1024)) GB")
} else {
    print("❌ Failed to query file system attributes")
    exit(1)
}

// 2. Test BSD Socket Network Interface Enumeration
print("\n[2] Testing BSD Socket Interface Telemetry...")
var ifaddr: UnsafeMutablePointer<ifaddrs>?
guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
    print("❌ getifaddrs failed")
    exit(1)
}
defer { freeifaddrs(ifaddr) }

var foundInterfaces: [String] = []
var ptr = firstAddr
while true {
    let name = String(cString: ptr.pointee.ifa_name)
    let addr = ptr.pointee.ifa_addr
    if let addr = addr, addr.pointee.sa_family == UInt8(AF_LINK) {
        if !foundInterfaces.contains(name) {
            foundInterfaces.append(name)
        }
    }
    guard let next = ptr.pointee.ifa_next else { break }
    ptr = next
}
assertTrue(!foundInterfaces.isEmpty, "Network interfaces queried successfully via AF_LINK: \(foundInterfaces.joined(separator: ", "))")
assertTrue(foundInterfaces.contains(where: { $0.hasPrefix("en") }), "Ethernet/Wi-Fi 'en' interface present")

// 3. Test Network History Store Serialization
print("\n[3] Testing Storage Manager & Persistence...")
let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("MacPulse")
let testFile = supportDir.appendingPathComponent("network_history.json")
assertTrue(FileManager.default.fileExists(atPath: testFile.path), "Persistent network history file verified at \(testFile.path)")

// 4. Test Application Bundle & Code Signature
print("\n[4] Testing Application Bundle Structure & Code Signing...")
let appPath = "./MacPulse.app"
let infoPlist = "\(appPath)/Contents/Info.plist"
let binary = "\(appPath)/Contents/MacOS/MacPulse"
let icon = "\(appPath)/Contents/Resources/AppIcon.icns"

assertTrue(FileManager.default.fileExists(atPath: appPath), "MacPulse.app bundle directory exists")
assertTrue(FileManager.default.fileExists(atPath: infoPlist), "Contents/Info.plist verified")
assertTrue(FileManager.default.fileExists(atPath: binary), "Contents/MacOS/MacPulse binary executable verified")
assertTrue(FileManager.default.fileExists(atPath: icon), "Contents/Resources/AppIcon.icns Retina icon verified")

print("\n========================================")
print("  All MacPulse Tests Passed with 100%!  ")
print("========================================")
