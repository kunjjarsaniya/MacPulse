import SwiftUI
import AppKit

// MARK: - MacPulse Centralized Design Tokens
// A unified, Apple HIG-inspired design system for all MacPulse components.

public enum MacPulseColors {
    // MARK: - Chassis & Backgrounds
    public static let islandBackground = Color(hex: "#0A0A0C")
    public static let backgroundDark = Color(red: 0.08, green: 0.09, blue: 0.12)
    public static let surfaceDark = Color(red: 0.12, green: 0.13, blue: 0.17)
    public static let surfaceElevated = Color(red: 0.16, green: 0.18, blue: 0.23)
    
    // MARK: - Dynamic Island Surfaces
    public static let cardBackground = Color.white.opacity(0.05)
    public static let cardBackgroundElevated = Color.white.opacity(0.08)
    public static let cardBackgroundSubtle = Color.white.opacity(0.04)
    public static let pillBackground = Color.white.opacity(0.06)
    public static let activeTabPill = Color.white.opacity(0.18)
    
    // MARK: - Borders & Hairlines
    public static let hairline = Color.white.opacity(0.08)
    public static let borderSubtle = Color.white.opacity(0.08)
    public static let borderMedium = Color.white.opacity(0.12)
    public static let borderHover = Color.white.opacity(0.18)
    public static let borderFocus = Color.white.opacity(0.20)
    public static let divider = Color.white.opacity(0.14)
    
    // MARK: - Typography & Text Tiers
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.68)
    public static let textTertiary = Color.white.opacity(0.42)
    public static let textQuaternary = Color.white.opacity(0.24)
    
    // MARK: - Sophisticated Monochromatic Apple Palette
    public static let monoPrimary = Color.white
    public static let monoSecondary = Color.white.opacity(0.68)
    public static let monoTertiary = Color.white.opacity(0.42)
    public static let monoQuaternary = Color.white.opacity(0.24)
    public static let monoBorder = Color.white.opacity(0.09)
    public static let monoBorderHover = Color.white.opacity(0.18)
    public static let monoSurface = Color.white.opacity(0.05)
    public static let monoSurfaceElevated = Color.white.opacity(0.10)
    public static let monoDivider = Color.white.opacity(0.16)
    
    // MARK: - Apple HIG Accent Colors
    public static let appleBlue = Color(hex: "#0A84FF")
    public static let appleCyan = Color(hex: "#38BDF8")
    public static let appleGreen = Color(hex: "#30D158")
    public static let appleYellow = Color(hex: "#FFD60A")
    public static let appleOrange = Color(hex: "#FF9F0A")
    public static let appleRed = Color(hex: "#FF453A")
    public static let applePurple = Color(hex: "#A855F7")
    
    // MARK: - Music & Streaming Brand Accents
    public static let spotifyGreen = Color(hex: "#1DB954")
    public static let appleMusicRed = Color(hex: "#FA2D48")
    
    // MARK: - Semantic Gradients
    public static let downloadGradient = LinearGradient(
        colors: [appleCyan, appleBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let uploadGradient = LinearGradient(
        colors: [applePurple, Color(hex: "#F43F5E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cpuGradient = LinearGradient(
        colors: [appleOrange, appleRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let ramGradient = LinearGradient(
        colors: [appleBlue, applePurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let glassCardBorder = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let rimLightGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.20),
            Color.white.opacity(0.04),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public enum MacPulseTypography {
    public static let micro = Font.system(size: 7, weight: .bold)
    public static let caption2 = Font.system(size: 8, weight: .medium)
    public static let caption2Bold = Font.system(size: 8, weight: .bold, design: .rounded)
    public static let caption = Font.system(size: 9, weight: .medium)
    public static let captionSemibold = Font.system(size: 9, weight: .semibold)
    public static let captionBold = Font.system(size: 9, weight: .bold)
    public static let footnote = Font.system(size: 10, weight: .regular)
    public static let footnoteMedium = Font.system(size: 10, weight: .medium)
    public static let footnoteSemibold = Font.system(size: 10, weight: .semibold)
    public static let footnoteBold = Font.system(size: 10, weight: .bold)
    public static let footnoteRounded = Font.system(size: 10.5, weight: .bold, design: .rounded)
    public static let subheadline = Font.system(size: 11, weight: .semibold)
    public static let headline = Font.system(size: 12, weight: .bold)
    public static let body = Font.system(size: 13, weight: .regular)
    public static let metric = Font.system(size: 14, weight: .bold, design: .rounded)
    public static let metricMono = Font.system(size: 9.5, weight: .semibold, design: .monospaced)
    public static let timerDisplay = Font.system(size: 26, weight: .heavy, design: .rounded)
}

public enum MacPulseSpacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 10
    public static let xl: CGFloat = 12
    public static let xxl: CGFloat = 16
    public static let gutter: CGFloat = 14
}

public enum MacPulseRadius {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 6
    public static let md: CGFloat = 8
    public static let button: CGFloat = 10
    public static let card: CGFloat = 12
    public static let compactChassis: CGFloat = 14
    public static let shelf: CGFloat = 14
    public static let media: CGFloat = 15
    public static let large: CGFloat = 18
    public static let chassis: CGFloat = 22
    public static let pill: CGFloat = 999
    
    // Curved Notch Geometry (Apple-Engineered Continuity)
    public static let topEarCompact: CGFloat = 8
    public static let topEarHUD: CGFloat = 10
    public static let topEarExpanded: CGFloat = 12
    public static let bottomCornerCompact: CGFloat = 14
    public static let bottomCornerHUD: CGFloat = 18
    public static let bottomCornerExpanded: CGFloat = 22
}

public enum MacPulseDimensions {
    public static let compactIslandSize = NSSize(width: 258, height: 28)
    public static let compactLiveActivitySize = NSSize(width: 280, height: 28)
    public static let hudIslandSize = NSSize(width: 340, height: 78)
    public static let alertIslandSize = NSSize(width: 360, height: 72)
    public static let expandedIslandSize = NSSize(width: 560, height: 175)
    
    public static let contentHeight: CGFloat = 118
    public static let actionButtonHeight: CGFloat = 34
    public static let iconSmall: CGFloat = 14
    public static let iconButtonSize: CGFloat = 22
    public static let albumArtSize: CGFloat = 72
}

public enum MacPulseAnimations {
    // True-to-life iOS Dynamic Island Motion Physics
    public static let islandSpring = Animation.spring(response: 0.30, dampingFraction: 0.78)
    public static let dynamicIslandExpand = Animation.spring(response: 0.34, dampingFraction: 0.74, blendDuration: 0.16)
    public static let dynamicIslandCollapse = Animation.spring(response: 0.28, dampingFraction: 0.70, blendDuration: 0.12)
    public static let jellySpring = Animation.spring(response: 0.28, dampingFraction: 0.58)
    public static let interactiveSpring = Animation.interactiveSpring(response: 0.24, dampingFraction: 0.82)
    public static let snappySpring = Animation.spring(response: 0.22, dampingFraction: 0.78)
    public static let smooth = Animation.easeInOut(duration: 0.20)
}

public enum MacPulseOpacity {
    public static let subtle: Double = 0.04
    public static let cardFill: Double = 0.05
    public static let surface: Double = 0.06
    public static let hairline: Double = 0.08
    public static let stroke: Double = 0.12
    public static let hover: Double = 0.18
    public static let activeTab: Double = 0.18
    public static let dimText: Double = 0.40
    public static let tertiaryText: Double = 0.45
    public static let secondaryText: Double = 0.65
    public static let primaryText: Double = 1.0
}
