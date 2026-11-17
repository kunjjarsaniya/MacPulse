import SwiftUI

// MARK: - Island Action Button
// Standardized quick action button for Dynamic Island utility stacks.

public struct IslandActionButton<Accessory: View>: View {
    private let title: String
    private let icon: String
    private let iconColor: Color
    private let accessory: Accessory
    private let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(
        title: String,
        icon: String,
        iconColor: Color = MacPulseColors.appleBlue,
        @ViewBuilder accessory: () -> Accessory,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.accessory = accessory()
        self.action = action
    }
    
    public var body: some View {
        Button {
            HapticFeedback.playSoft()
            action()
        } label: {
            HStack(spacing: MacPulseSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(MacPulseTypography.footnoteBold)
                    .foregroundColor(MacPulseColors.textPrimary)
                
                Spacer()
                
                accessory
            }
            .padding(.horizontal, MacPulseSpacing.lg)
            .frame(height: MacPulseDimensions.actionButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: MacPulseRadius.button, style: .continuous)
                    .fill(isHovered ? MacPulseColors.cardBackgroundElevated : MacPulseColors.pillBackground)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

public extension IslandActionButton where Accessory == EmptyView {
    init(
        title: String,
        icon: String,
        iconColor: Color = MacPulseColors.appleBlue,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            icon: icon,
            iconColor: iconColor,
            accessory: { EmptyView() },
            action: action
        )
    }
}
