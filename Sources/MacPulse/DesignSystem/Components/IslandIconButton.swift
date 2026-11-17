import SwiftUI

// MARK: - Island Icon Button
// Standardized circular/rounded icon button for island navigation and controls.

public struct IslandIconButton: View {
    private let icon: String
    private let iconSize: CGFloat
    private let iconWeight: Font.Weight
    private let foregroundColor: Color
    private let backgroundColor: Color
    private let size: CGFloat
    private let tooltip: String?
    private let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(
        icon: String,
        iconSize: CGFloat = 10,
        iconWeight: Font.Weight = .medium,
        foregroundColor: Color = MacPulseColors.textSecondary,
        backgroundColor: Color = Color.white.opacity(0.08),
        size: CGFloat = MacPulseDimensions.iconButtonSize,
        tooltip: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconSize = iconSize
        self.iconWeight = iconWeight
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.size = size
        self.tooltip = tooltip
        self.action = action
    }
    
    public var body: some View {
        Button {
            HapticFeedback.playSoft()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: iconWeight))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isHovered ? backgroundColor.opacity(1.5) : backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(tooltip ?? "")
    }
}
