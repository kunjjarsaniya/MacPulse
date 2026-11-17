import Foundation
import Network
import AppKit
import Combine

public final class NetworkMonitorService: ObservableObject {
    public static let shared = NetworkMonitorService()
    
    // Published states for UI
    @Published public private(set) var currentDownloadSpeed: Double = 0.0 // bytes per sec
    @Published public private(set) var currentUploadSpeed: Double = 0.0 // bytes per sec
    @Published public private(set) var downloadSpeedHistory: [Double] = Array(repeating: 0.0, count: 30)
    @Published public private(set) var uploadSpeedHistory: [Double] = Array(repeating: 0.0, count: 30)
    
    @Published public private(set) var activeInterfaceName: String = "en0"
    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var connectionType: String = "Wi-Fi"
    @Published public private(set) var availableInterfaces: [NetworkInterfaceInfo] = []
    
    @Published public var selectedInterfaceOption: String = "auto" { // "auto", "all", or interface name (e.g. "en0")
        didSet {
            resetBaseline()
        }
    }
    
    private var pathMonitor: NWPathMonitor?
    private let pathQueue = DispatchQueue(label: "com.macpulse.network.path", qos: .utility)
    
    private var timer: DispatchSourceTimer?
    private let monitorQueue = DispatchQueue(label: "com.macpulse.network.poll", qos: .userInitiated)
    
    // Previous sample baseline
    private var lastPollTime: Date = Date()
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var isFirstSample: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPathMonitor()
        setupSleepWakeObservers()
        discoverInterfaces()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - NWPathMonitor for Connection Detection
    private func setupPathMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let isConnected = (path.status == .satisfied)
            
            var typeStr = "Unknown"
            if path.usesInterfaceType(.wifi) {
                typeStr = "Wi-Fi"
            } else if path.usesInterfaceType(.wiredEthernet) {
                typeStr = "Ethernet"
            } else if path.usesInterfaceType(.cellular) {
                typeStr = "Cellular"
            } else if path.usesInterfaceType(.loopback) {
                typeStr = "Loopback"
            }
            
            DispatchQueue.main.async {
                self.isConnected = isConnected
                self.connectionType = typeStr
                self.discoverInterfaces()
            }
        }
        monitor.start(queue: pathQueue)
        self.pathMonitor = monitor
    }
    
    // MARK: - Sleep & Wake Handling
    private func setupSleepWakeObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetBaseline()
            NetworkHistoryStore.shared.checkDateRollover()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resetBaseline()
        }
    }
    
    public func resetBaseline() {
        isFirstSample = true
        lastBytesIn = 0
        lastBytesOut = 0
        lastPollTime = Date()
    }
    
    // MARK: - Start & Stop Monitoring
    public func startMonitoring(interval: TimeInterval = 1.0) {
        stopMonitoring()
        
        let timer = DispatchSource.makeTimerSource(queue: monitorQueue)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.sampleNetworkCounters()
        }
        timer.resume()
        self.timer = timer
    }
    
    public func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - Discover Interfaces via getifaddrs
    public func discoverInterfaces() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }
        
        var list: [NetworkInterfaceInfo] = []
        var seenNames = Set<String>()
        
        var ptr = firstAddr
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK
            
            if !isLoopback && !seenNames.contains(name) && (name.hasPrefix("en") || name.hasPrefix("bridge")) {
                seenNames.insert(name)
                let isWiFi = (name == "en0" && connectionType == "Wi-Fi") || name == "en1"
                let displayName = isWiFi ? "Wi-Fi (\(name))" : "Ethernet (\(name))"
                list.append(NetworkInterfaceInfo(
                    name: name,
                    displayName: displayName,
                    isWiFi: isWiFi,
                    isActive: isUp && isRunning
                ))
            }
            
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }
        
        DispatchQueue.main.async {
            self.availableInterfaces = list
            if self.selectedInterfaceOption == "auto" {
                if let active = list.first(where: { $0.isActive }) {
                    self.activeInterfaceName = active.name
                }
            } else if self.selectedInterfaceOption != "all" {
                self.activeInterfaceName = self.selectedInterfaceOption
            }
        }
    }
    
    // MARK: - Byte Counter Sampling via BSD Sockets
    private func sampleNetworkCounters() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }
        
        var currentIn: UInt64 = 0
        var currentOut: UInt64 = 0
        
        var ptr = firstAddr
        let targetInterface = (selectedInterfaceOption == "auto") ? activeInterfaceName : selectedInterfaceOption
        let matchAll = (selectedInterfaceOption == "all")
        
        while true {
            let name = String(cString: ptr.pointee.ifa_name)
            let addr = ptr.pointee.ifa_addr
            
            if let addr = addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                if matchAll {
                    let isLoopback = (Int32(ptr.pointee.ifa_flags) & IFF_LOOPBACK) != 0
                    if !isLoopback && (name.hasPrefix("en") || name.hasPrefix("pdp_ip")) {
                        if let dataPtr = ptr.pointee.ifa_data {
                            let networkData = dataPtr.assumingMemoryBound(to: if_data.self)
                            currentIn += UInt64(networkData.pointee.ifi_ibytes)
                            currentOut += UInt64(networkData.pointee.ifi_obytes)
                        }
                    }
                } else if name == targetInterface {
                    if let dataPtr = ptr.pointee.ifa_data {
                        let networkData = dataPtr.assumingMemoryBound(to: if_data.self)
                        currentIn = UInt64(networkData.pointee.ifi_ibytes)
                        currentOut = UInt64(networkData.pointee.ifi_obytes)
                        break
                    }
                }
            }
            
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }
        
        let now = Date()
        let elapsed = max(0.1, now.timeIntervalSince(lastPollTime))
        
        if isFirstSample {
            isFirstSample = false
            lastBytesIn = currentIn
            lastBytesOut = currentOut
            lastPollTime = now
            return
        }
        
        // Calculate deltas safely
        let deltaIn: UInt64
        if currentIn >= lastBytesIn {
            deltaIn = currentIn - lastBytesIn
        } else {
            // Counter overflow or interface reset
            deltaIn = 0
        }
        
        let deltaOut: UInt64
        if currentOut >= lastBytesOut {
            deltaOut = currentOut - lastBytesOut
        } else {
            deltaOut = 0
        }
        
        lastBytesIn = currentIn
        lastBytesOut = currentOut
        lastPollTime = now
        
        let downloadSpeed = Double(deltaIn) / elapsed
        let uploadSpeed = Double(deltaOut) / elapsed
        
        // Update history store with deltas
        NetworkHistoryStore.shared.addUsage(
            downloadDelta: deltaIn,
            uploadDelta: deltaOut,
            currentDownloadSpeed: downloadSpeed,
            currentUploadSpeed: uploadSpeed
        )
        
        DispatchQueue.main.async {
            self.currentDownloadSpeed = downloadSpeed
            self.currentUploadSpeed = uploadSpeed
            
            var newDownHistory = self.downloadSpeedHistory
            newDownHistory.removeFirst()
            newDownHistory.append(downloadSpeed)
            self.downloadSpeedHistory = newDownHistory
            
            var newUpHistory = self.uploadSpeedHistory
            newUpHistory.removeFirst()
            newUpHistory.append(uploadSpeed)
            self.uploadSpeedHistory = newUpHistory
        }
    }
}
