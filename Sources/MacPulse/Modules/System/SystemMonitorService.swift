import Foundation
import AppKit
import Combine
import IOKit.ps
import MachO

public final class SystemMonitorService: ObservableObject {
    public static let shared = SystemMonitorService()
    
    @Published public private(set) var cpu = CPUSnapshot()
    @Published public private(set) var ram = RAMSnapshot()
    @Published public private(set) var disk = DiskSnapshot()
    @Published public private(set) var battery = BatterySnapshot()
    @Published public private(set) var uptime = UptimeSnapshot()
    @Published public private(set) var topProcesses: [TopProcessItem] = []
    
    @Published public private(set) var cpuHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published public private(set) var ramHistory: [Double] = Array(repeating: 0.0, count: 30)
    
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.macpulse.system.poll", qos: .userInitiated)
    
    // Previous state tracking
    private var previousCPULoad: host_cpu_load_info?
    private var previousIsPluggedIn: Bool? = nil
    
    private init() {
        cpu.coreCount = ProcessInfo.processInfo.processorCount
        sampleAll()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring(interval: TimeInterval = 1.5) {
        stopMonitoring()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.sampleAll()
        }
        timer.resume()
        self.timer = timer
    }
    
    public func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }
    
    public func sampleAll() {
        let newCPU = sampleCPU()
        let newRAM = sampleRAM()
        let newDisk = sampleDisk()
        let newBattery = sampleBattery()
        let newUptime = sampleUptime()
        
        DispatchQueue.main.async {
            self.cpu = newCPU
            self.ram = newRAM
            self.disk = newDisk
            self.battery = newBattery
            self.uptime = newUptime
            
            var cHistory = self.cpuHistory
            cHistory.removeFirst()
            cHistory.append(newCPU.usagePercentage)
            self.cpuHistory = cHistory
            
            var rHistory = self.ramHistory
            rHistory.removeFirst()
            rHistory.append(newRAM.usagePercentage)
            self.ramHistory = rHistory
            
            // Check for charging/plugged-in transition
            if let prev = self.previousIsPluggedIn, prev != newBattery.isPluggedIn {
                NotificationCenter.default.post(
                    name: NSNotification.Name("com.macpulse.powerChanged"),
                    object: nil,
                    userInfo: ["isPluggedIn": newBattery.isPluggedIn, "percentage": newBattery.percentage]
                )
            }
            self.previousIsPluggedIn = newBattery.isPluggedIn
        }
    }
    
    // MARK: - Top Resource Consumers Scanner via /bin/ps
    public func fetchTopProcesses(limit: Int = 3) {
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/ps")
            task.arguments = ["-Aceo", "pid,pcpu,pmem,comm", "-r"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                
                guard let str = String(data: data, encoding: .utf8) else { return }
                var items: [TopProcessItem] = []
                let lines = str.components(separatedBy: "\n")
                let totalRAM = Double(ProcessInfo.processInfo.physicalMemory)
                
                for line in lines.dropFirst() {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    guard parts.count >= 4,
                          let pid = Int32(parts[0]),
                          let cpu = Double(parts[1]),
                          let pmem = Double(parts[2]) else { continue }
                    
                    let rawName = parts[3...].joined(separator: " ")
                    let app = NSRunningApplication(processIdentifier: pid)
                    let displayName = app?.localizedName ?? (rawName as NSString).lastPathComponent
                    let icon = app?.icon
                    let memBytes = UInt64((pmem / 100.0) * totalRAM)
                    
                    items.append(TopProcessItem(
                        id: pid,
                        name: displayName,
                        cpuPercentage: cpu,
                        memoryBytes: memBytes,
                        icon: icon
                    ))
                    if items.count >= limit { break }
                }
                
                DispatchQueue.main.async {
                    self.topProcesses = items
                }
            } catch {
                // Non-fatal
            }
        }
    }
    
    // MARK: - CPU Sampling via Mach Host Statistics
    private func sampleCPU() -> CPUSnapshot {
        var snapshot = CPUSnapshot()
        snapshot.coreCount = ProcessInfo.processInfo.processorCount
        
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var cpuLoadInfo = host_cpu_load_info()
        
        let kerr = withUnsafeMutablePointer(to: &cpuLoadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return cpu
        }
        
        if let prev = previousCPULoad {
            let userDiff = Double(cpuLoadInfo.cpu_ticks.0 - prev.cpu_ticks.0)
            let sysDiff = Double(cpuLoadInfo.cpu_ticks.1 - prev.cpu_ticks.1)
            let idleDiff = Double(cpuLoadInfo.cpu_ticks.2 - prev.cpu_ticks.2)
            let niceDiff = Double(cpuLoadInfo.cpu_ticks.3 - prev.cpu_ticks.3)
            
            let totalTicks = userDiff + sysDiff + idleDiff + niceDiff
            if totalTicks > 0 {
                let userPerc = (userDiff / totalTicks) * 100.0
                let sysPerc = (sysDiff / totalTicks) * 100.0
                let idlePerc = (idleDiff / totalTicks) * 100.0
                let usedPerc = ((userDiff + sysDiff + niceDiff) / totalTicks) * 100.0
                
                snapshot.usagePercentage = min(max(usedPerc, 0.0), 100.0)
                snapshot.userPercentage = min(max(userPerc, 0.0), 100.0)
                snapshot.systemPercentage = min(max(sysPerc, 0.0), 100.0)
                snapshot.idlePercentage = min(max(idlePerc, 0.0), 100.0)
            }
        }
        
        previousCPULoad = cpuLoadInfo
        return snapshot
    }
    
    // MARK: - RAM Sampling via Mach VM Statistics
    private func sampleRAM() -> RAMSnapshot {
        var snapshot = RAMSnapshot()
        snapshot.totalBytes = ProcessInfo.processInfo.physicalMemory
        
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64()
        
        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return ram
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let inactive = UInt64(vmStats.inactive_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        
        let used = active + wired + compressed
        
        snapshot.activeBytes = active
        snapshot.wiredBytes = wired
        snapshot.compressedBytes = compressed
        snapshot.freeBytes = free + inactive
        snapshot.usedBytes = min(used, snapshot.totalBytes)
        
        return snapshot
    }
    
    // MARK: - Disk Sampling via FileManager Attributes
    private func sampleDisk() -> DiskSnapshot {
        var snapshot = DiskSnapshot()
        
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            let total = (attrs[.systemSize] as? NSNumber)?.uint64Value ?? 0
            let free = (attrs[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
            snapshot.totalBytes = total
            snapshot.freeBytes = free
            snapshot.usedBytes = total > free ? (total - free) : 0
        }
        
        return snapshot
    }
    
    // MARK: - Battery Sampling via IOPowerSources & AppleSmartBattery
    private func sampleBattery() -> BatterySnapshot {
        var snapshot = BatterySnapshot()
        
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return snapshot
        }
        
        for pSource in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, pSource)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            snapshot.hasBattery = true
            
            if let curCap = desc[kIOPSCurrentCapacityKey] as? Int,
               let maxCap = desc[kIOPSMaxCapacityKey] as? Int, maxCap > 0 {
                snapshot.percentage = Int((Double(curCap) / Double(maxCap)) * 100.0)
            }
            
            if let isCharging = desc[kIOPSIsChargingKey] as? Bool {
                snapshot.isCharging = isCharging
            }
            
            if let powerSource = desc[kIOPSPowerSourceStateKey] as? String {
                snapshot.isPluggedIn = (powerSource == kIOPSACPowerValue)
            }
            
            if let timeRemaining = desc[kIOPSTimeToEmptyKey] as? Int, timeRemaining > 0 {
                snapshot.timeRemainingMinutes = timeRemaining
            }
        }
        
        // Detailed battery health from IOKit AppleSmartBattery
        let matchDict = IOServiceMatching("AppleSmartBattery")
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, matchDict)
        if entry != 0 {
            defer { IOObjectRelease(entry) }
            
            if let cycleCount = IORegistryEntryCreateCFProperty(entry, "CycleCount" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                snapshot.cycleCount = cycleCount
            }
            
            let maxCap = IORegistryEntryCreateCFProperty(entry, "MaxCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int ?? 0
            let designCap = IORegistryEntryCreateCFProperty(entry, "DesignCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int ?? 0
            
            if designCap > 0 && maxCap > 0 {
                snapshot.healthPercentage = min(100, Int((Double(maxCap) / Double(designCap)) * 100.0))
            }
            
            if let temp = IORegistryEntryCreateCFProperty(entry, "Temperature" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                // Temperature is in hundredths/tenths of Kelvin (e.g. 2931 -> 20.0 C)
                snapshot.temperatureCelsius = (Double(temp) / 10.0) - 273.15
            }
            
            if let condition = IORegistryEntryCreateCFProperty(entry, "PermanentFailureStatus" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int, condition != 0 {
                snapshot.condition = "Service Recommended"
            } else {
                snapshot.condition = "Normal"
            }
        }
        
        return snapshot
    }
    
    // MARK: - Uptime Sampling
    private func sampleUptime() -> UptimeSnapshot {
        var snapshot = UptimeSnapshot()
        let uptimeSeconds = ProcessInfo.processInfo.systemUptime
        snapshot.uptimeSeconds = uptimeSeconds
        snapshot.bootDate = Date().addingTimeInterval(-uptimeSeconds)
        return snapshot
    }
}
