import AppKit
import Foundation

// MARK: - Centralized Haptic & Sound Feedback Service
// Eliminates code duplication across all MacPulse components.

public enum HapticFeedback {
    public static func playSoft() {
        DispatchQueue.main.async {
            if let sound = NSSound(named: "Tink") {
                sound.volume = 0.2
                sound.play()
            }
        }
    }
    
    public static func playAlert() {
        DispatchQueue.main.async {
            if let sound = NSSound(named: "Glass") {
                sound.volume = 0.5
                sound.play()
            } else {
                NSSound.beep()
            }
        }
    }
    
    public static func playBeep() {
        DispatchQueue.main.async {
            NSSound.beep()
        }
    }
}
