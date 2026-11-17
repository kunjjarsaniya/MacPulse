import Foundation
import UserNotifications
import AppKit

public final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    // Ensure notifications appear as banners even when app is active
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    public func playAlertSound(name: String = "Glass") {
        DispatchQueue.main.async {
            if let sound = NSSound(named: NSSound.Name(name)) {
                sound.play()
            } else if let fallback = NSSound(named: NSSound.Name("Ping")) {
                fallback.play()
            } else {
                NSSound.beep()
            }
        }
    }
    
    public func sendNotification(title: String, subtitle: String? = nil, body: String, soundName: String = "Glass") {
        playAlertSound(name: soundName)
        
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
}
