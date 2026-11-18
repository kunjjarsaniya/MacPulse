import Foundation
import ServiceManagement

public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            if SMAppService.mainApp.status == .enabled {
                return true
            }
        }
        return checkSystemEventsLoginItem()
    }
    
    public func setEnabled(_ enabled: Bool) -> Bool {
        var success = false
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                success = true
            } catch {
                print("LaunchAtLoginManager SMAppService: \(error.localizedDescription)")
            }
        }
        
        // Also register/unregister via System Events Login Items as rock-solid fallback
        let scriptSuccess = setSystemEventsLoginItem(enabled: enabled)
        return success || scriptSuccess
    }
    
    private func checkSystemEventsLoginItem() -> Bool {
        let script = "tell application \"System Events\" to exists login item \"MacPulse\""
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let result = appleScript?.executeAndReturnError(&error).booleanValue ?? false
        return result
    }
    
    private func setSystemEventsLoginItem(enabled: Bool) -> Bool {
        let appPath = Bundle.main.bundlePath
        let script: String
        if enabled {
            script = """
            tell application "System Events"
                if not (exists login item "MacPulse") then
                    make new login item at end of login items with properties {name:"MacPulse", path:"\(appPath)", hidden:false}
                end if
            end tell
            """
        } else {
            script = """
            tell application "System Events"
                if exists login item "MacPulse" then
                    delete login item "MacPulse"
                end if
            end tell
            """
        }
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        _ = appleScript?.executeAndReturnError(&error)
        return error == nil
    }
}
