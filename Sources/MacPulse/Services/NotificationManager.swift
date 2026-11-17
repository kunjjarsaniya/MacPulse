import Foundation
import UserNotifications
import AppKit

public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    public func playAlertSound(name: String = "Glass") {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    public func sendNotification(title: String, subtitle: String? = nil, body: String, soundName: String = "Glass") {
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
        
        UNUserNotificationCenter.current().add(request) { [weak self] _ in
            DispatchQueue.main.async {
                self?.playAlertSound(name: soundName)
            }
        }
    }
}
