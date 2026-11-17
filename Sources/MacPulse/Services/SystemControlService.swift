import AppKit
import AudioToolbox
import CoreAudio
import Foundation
import SwiftUI

// MARK: - System Control Service (Native Volume & Screen Brightness)
// Uses direct CoreAudio VirtualMainVolume and DisplayServices APIs for genuine macOS hardware control.

@MainActor
public final class SystemControlService: ObservableObject {
    public static let shared = SystemControlService()
    
    // Published real system values (0.0 ... 1.0)
    @Published public private(set) var volume: Double = 0.5
    @Published public private(set) var brightness: Double = 0.75
    @Published public private(set) var isMuted: Bool = false
    
    private var defaultOutputDeviceID: AudioDeviceID = 0
    private var displayServicesHandle: UnsafeMutableRawPointer?
    private var getBrightnessPtr: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32)?
    private var setBrightnessPtr: (@convention(c) (CGDirectDisplayID, Float) -> Int32)?
    
    private var pollTimer: Timer?
    
    private init() {
        setupCoreAudio()
        setupDisplayServices()
        refreshVolume()
        refreshBrightness()
        startPeriodicSync()
    }
    
    deinit {
        pollTimer?.invalidate()
        if let handle = displayServicesHandle {
            dlclose(handle)
        }
    }
    
    // MARK: - CoreAudio Volume Setup
    private func setupCoreAudio() {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        if status == noErr {
            self.defaultOutputDeviceID = deviceID
            installVolumeListener()
        }
    }
    
    private func installVolumeListener() {
        guard defaultOutputDeviceID != 0 else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            defaultOutputDeviceID,
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            Task { @MainActor in
                self?.refreshVolume()
            }
        }
    }
    
    public func refreshVolume() {
        guard defaultOutputDeviceID != 0 else {
            // Re-resolve device if needed
            setupCoreAudio()
            return
        }
        
        var vol: Float32 = 0.0
        var size = UInt32(MemoryLayout.size(ofValue: vol))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &size,
            &vol
        )
        
        if status == noErr {
            let clamped = Double(min(max(vol, 0.0), 1.0))
            if abs(self.volume - clamped) > 0.005 {
                self.volume = clamped
                self.isMuted = clamped < 0.01
            }
        }
    }
    
    public func setVolume(_ newVolume: Double) {
        let clamped = Float32(min(max(newVolume, 0.0), 1.0))
        self.volume = Double(clamped)
        self.isMuted = clamped < 0.01
        
        guard defaultOutputDeviceID != 0 else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var val = clamped
        let size = UInt32(MemoryLayout.size(ofValue: val))
        _ = AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            size,
            &val
        )
    }
    
    // MARK: - DisplayServices Screen Brightness Setup
    private func setupDisplayServices() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            return
        }
        self.displayServicesHandle = handle
        
        if let symGet = dlsym(handle, "DisplayServicesGetBrightness") {
            self.getBrightnessPtr = unsafeBitCast(symGet, to: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32).self)
        }
        if let symSet = dlsym(handle, "DisplayServicesSetBrightness") {
            self.setBrightnessPtr = unsafeBitCast(symSet, to: (@convention(c) (CGDirectDisplayID, Float) -> Int32).self)
        }
    }
    
    public func refreshBrightness() {
        guard let getBrightness = getBrightnessPtr else { return }
        let mainDisplay = CGMainDisplayID()
        var b: Float = 0.0
        let res = getBrightness(mainDisplay, &b)
        if res == 0 {
            let clamped = Double(min(max(b, 0.0), 1.0))
            if abs(self.brightness - clamped) > 0.005 {
                self.brightness = clamped
            }
        }
    }
    
    public func setBrightness(_ newBrightness: Double) {
        let clamped = Float(min(max(newBrightness, 0.0), 1.0))
        self.brightness = Double(clamped)
        
        guard let setBrightness = setBrightnessPtr else { return }
        let mainDisplay = CGMainDisplayID()
        _ = setBrightness(mainDisplay, clamped)
    }
    
    // MARK: - Periodic Synchronization (Safety Net)
    private func startPeriodicSync() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshVolume()
                self?.refreshBrightness()
            }
        }
    }
}
