import SwiftUI

// MARK: - Modern UI Controls

public struct SegmentedPillPicker<T: Hashable & CustomStringConvertible>: View {
    @Binding public var selection: T
    public let items: [T]
    
    public init(selection: Binding<T>, items: [T]) {
        self._selection = selection
        self.items = items
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                        selection = item
                    }
                } label: {
                    Text(item.description)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : MacPulseTheme.textSecondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.18),
                                                Color.white.opacity(0.08)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(MacPulseTheme.borderSubtle, lineWidth: 1)
                )
        )
    }
}

public struct ModernActionButton: View {
    public let title: String
    public let icon: String
    public let gradient: LinearGradient
    public let action: () -> Void
    
    @State private var isHovered = false
    
    public init(
        title: String,
        icon: String,
        gradient: LinearGradient = MacPulseTheme.downloadGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(gradient)
                    .opacity(isHovered ? 1.0 : 0.85)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

public struct StatusBadge: View {
    public let text: String
    public let color: Color
    public let icon: String?
    
    public init(text: String, color: Color = MacPulseTheme.accentGreen, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .shadow(color: color.opacity(0.8), radius: 3)
            }
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.vertical, 4)
        .padding(.horizontal, 9)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule().stroke(color.opacity(0.28), lineWidth: 0.8)
                )
        )
    }
}
