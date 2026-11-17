import SwiftUI

// MARK: - Glassmorphic Card Container

public struct GlassCard<Content: View>: View {
    private let content: Content
    private let cornerRadius: CGFloat
    private let interactive: Bool
    
    @State private var isHovered: Bool = false
    
    public init(
        cornerRadius: CGFloat = MacPulseTheme.cornerRadiusLarge,
        interactive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.interactive = interactive
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(18)
            .background {
                ZStack {
                    // Base ultra thin material for macOS vibrancy
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Dark depth gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered && interactive ? 0.07 : 0.04),
                                    Color.black.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isHovered && interactive ?
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            MacPulseTheme.glassCardBorder,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(isHovered && interactive ? 0.45 : 0.25),
                radius: isHovered && interactive ? 16 : 10,
                x: 0,
                y: isHovered && interactive ? 8 : 4
            )
            .scaleEffect(isHovered && interactive ? 1.008 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHovered)
            .onHover { hovering in
                if interactive {
                    isHovered = hovering
                }
            }
    }
}
