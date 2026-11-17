import SwiftUI
import AppKit

// MARK: - Theme & Design System

public enum MacPulseTheme {
    // MARK: - Colors
    public static let backgroundDark = Color(red: 0.08, green: 0.09, blue: 0.12)
    public static let surfaceDark = Color(red: 0.12, green: 0.13, blue: 0.17)
    public static let surfaceElevated = Color(red: 0.16, green: 0.18, blue: 0.23)
    
    // Accents
    public static let accentBlue = Color(red: 0.04, green: 0.52, blue: 1.00) // #0A84FF
    public static let accentCyan = Color(red: 0.00, green: 0.78, blue: 0.74) // #00C7BE
    public static let accentGreen = Color(red: 0.19, green: 0.82, blue: 0.35) // #30D158
    public static let accentPurple = Color(red: 0.69, green: 0.32, blue: 0.87) // #AF52DE
    public static let accentOrange = Color(red: 1.00, green: 0.62, blue: 0.04) // #FF9F0A
    public static let accentRed = Color(red: 1.00, green: 0.27, blue: 0.23) // #FF453A
    public static let accentYellow = Color(red: 1.00, green: 0.84, blue: 0.04) // #FFD60A
    
    // Text colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textTertiary = Color.white.opacity(0.40)
    
    // Border & Divider
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderHover = Color.white.opacity(0.18)
    public static let borderAccent = accentBlue.opacity(0.4)
    
    // MARK: - Gradients
    public static let downloadGradient = LinearGradient(
        colors: [Color(red: 0.00, green: 0.78, blue: 0.74), Color(red: 0.04, green: 0.52, blue: 1.00)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let uploadGradient = LinearGradient(
        colors: [Color(red: 0.69, green: 0.32, blue: 0.87), Color(red: 0.95, green: 0.35, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cpuGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.62, blue: 0.04), Color(red: 1.00, green: 0.27, blue: 0.23)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let ramGradient = LinearGradient(
        colors: [Color(red: 0.04, green: 0.52, blue: 1.00), Color(red: 0.69, green: 0.32, blue: 0.87)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let pomodoroGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.35, blue: 0.35), Color(red: 0.95, green: 0.20, blue: 0.40)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let breakGradient = LinearGradient(
        colors: [Color(red: 0.19, green: 0.82, blue: 0.35), Color(red: 0.00, green: 0.78, blue: 0.74)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let glassCardBorder = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Visual Effects
    public static let cornerRadiusLarge: CGFloat = 18
    public static let cornerRadiusMedium: CGFloat = 12
    public static let cornerRadiusSmall: CGFloat = 8
    
    public static let cardShadow = Shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
}

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}
