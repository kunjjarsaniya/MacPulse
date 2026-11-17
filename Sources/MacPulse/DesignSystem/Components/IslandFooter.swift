import SwiftUI

// MARK: - Island Footer
// Standardized bottom status and action row for Dynamic Island tabs.

public struct IslandFooter<Actions: View>: View {
    private let statusText: String
    private let actions: Actions
    
    public init(
        statusText: String,
        @ViewBuilder actions: () -> Actions
    ) {
        self.statusText = statusText
        self.actions = actions()
    }
    
    public var body: some View {
        HStack {
            Text(statusText)
                .font(MacPulseTypography.caption)
                .foregroundColor(MacPulseColors.textTertiary)
            
            Spacer()
            
            actions
        }
        .padding(.horizontal, MacPulseSpacing.sm)
    }
}

public extension IslandFooter where Actions == EmptyView {
    init(statusText: String) {
        self.init(statusText: statusText, actions: { EmptyView() })
    }
}
