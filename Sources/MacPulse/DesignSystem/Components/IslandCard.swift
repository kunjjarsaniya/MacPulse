import SwiftUI

// MARK: - Island Card Container
// Standardized glassmorphic card container with continuous squircle corners.

public struct IslandCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let fillColor: Color
    private let strokeColor: Color
    private let content: Content
    
    public init(
        cornerRadius: CGFloat = MacPulseRadius.card,
        fillColor: Color = MacPulseColors.cardBackground,
        strokeColor: Color = MacPulseColors.hairline,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(strokeColor, lineWidth: 0.6)
                    )
            )
    }
}
