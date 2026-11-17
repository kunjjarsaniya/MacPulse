import SwiftUI
import AppKit

// MARK: - Theme & Design System

public enum MacPulseTheme {
    // MARK: - Direct Token Aliases
    public typealias Colors = MacPulseColors
    public typealias Typography = MacPulseTypography
    public typealias Spacing = MacPulseSpacing
    public typealias Radius = MacPulseRadius
    public typealias Dimensions = MacPulseDimensions
    public typealias Animations = MacPulseAnimations
    public typealias Opacity = MacPulseOpacity

    // MARK: - Colors (Backward Compatible)
    public static let backgroundDark = MacPulseColors.backgroundDark
    public static let surfaceDark = MacPulseColors.surfaceDark
    public static let surfaceElevated = MacPulseColors.surfaceElevated
    
    // Accents
    public static let accentBlue = MacPulseColors.appleBlue
    public static let accentCyan = MacPulseColors.appleCyan
    public static let accentGreen = MacPulseColors.appleGreen
    public static let accentPurple = MacPulseColors.applePurple
    public static let accentOrange = MacPulseColors.appleOrange
    public static let accentRed = MacPulseColors.appleRed
    public static let accentYellow = MacPulseColors.appleYellow
    
    // Text colors
    public static let textPrimary = MacPulseColors.textPrimary
    public static let textSecondary = MacPulseColors.textSecondary
    public static let textTertiary = MacPulseColors.textTertiary
    
    // Border & Divider
    public static let borderSubtle = MacPulseColors.borderSubtle
    public static let borderHover = MacPulseColors.borderHover
    public static let borderAccent = MacPulseColors.appleBlue.opacity(0.4)
    
    // MARK: - Gradients
    public static let downloadGradient = MacPulseColors.downloadGradient
    public static let uploadGradient = MacPulseColors.uploadGradient
    public static let cpuGradient = MacPulseColors.cpuGradient
    public static let ramGradient = MacPulseColors.ramGradient
    
    public static let pomodoroGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.35, blue: 0.35), Color(red: 0.95, green: 0.20, blue: 0.40)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let breakGradient = LinearGradient(
        colors: [MacPulseColors.appleGreen, MacPulseColors.appleCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let glassCardBorder = MacPulseColors.glassCardBorder
    public static let rimLightGradient = MacPulseColors.rimLightGradient
    
    // MARK: - Visual Effects
    public static let cornerRadiusLarge = MacPulseRadius.large
    public static let cornerRadiusMedium = MacPulseRadius.card
    public static let cornerRadiusSmall = MacPulseRadius.md
    
    public static let cardShadow = Shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
}

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}

// MARK: - Color Hex Initializer
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Visual Effect Blur (Native AppKit Glass)
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

