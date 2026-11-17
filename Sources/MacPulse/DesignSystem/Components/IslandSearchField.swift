import SwiftUI

// MARK: - Island Search Field
// Universal search input for Dynamic Island sheets with clear button.

public struct IslandSearchField: View {
    @Binding public var text: String
    public let placeholder: String
    
    public init(text: Binding<String>, placeholder: String = "Search...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack(spacing: MacPulseSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(MacPulseColors.textTertiary)
            
            TextField(placeholder, text: $text)
                .font(MacPulseTypography.footnote)
                .textFieldStyle(.plain)
                .foregroundColor(MacPulseColors.textPrimary)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    HapticFeedback.playSoft()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(MacPulseColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MacPulseSpacing.md)
        .padding(.vertical, MacPulseSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MacPulseRadius.md, style: .continuous)
                .fill(MacPulseColors.pillBackground)
        )
    }
}
