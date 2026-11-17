import AppKit
import SwiftUI

// MARK: - Dynamic Island Clipboard View (Searchable Clipboard History)

public struct DynamicIslandClipboardView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            IslandSearchField(
                text: $clipboard.searchText,
                placeholder: "Search clipboard history..."
            )
            
            contentArea
            
            footerView
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if clipboard.filteredHistory.isEmpty {
            VStack {
                Spacer()
                Text("No clipboard history")
                    .font(MacPulseTypography.footnoteMedium)
                    .foregroundColor(MacPulseColors.textTertiary)
                Spacer()
            }
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: MacPulseSpacing.xs) {
                    ForEach(clipboard.filteredHistory) { entry in
                        clipboardRow(for: entry)
                    }
                }
            }
            .frame(maxHeight: 70)
        }
    }
    
    private func clipboardRow(for entry: ClipboardEntry) -> some View {
        HStack(spacing: MacPulseSpacing.sm) {
            Text(entry.content)
                .font(MacPulseTypography.footnote)
                .foregroundColor(MacPulseColors.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                clipboard.copyEntry(entry)
                controller.triggerToast(title: "Copied", subtitle: "Item copied back to clipboard")
                HapticFeedback.playSoft()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.80))
            }
            .buttonStyle(.plain)
            
            Button {
                clipboard.deleteEntry(id: entry.id)
                HapticFeedback.playSoft()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundColor(MacPulseColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MacPulseSpacing.md)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: MacPulseRadius.sm, style: .continuous)
                .fill(MacPulseColors.pillBackground)
        )
    }
    
    private var footerView: some View {
        IslandFooter(
            statusText: "\(clipboard.history.count) items recorded"
        ) {
            Button("Clear History") {
                clipboard.clearHistory()
                HapticFeedback.playSoft()
            }
            .font(MacPulseTypography.caption)
            .foregroundColor(Color.white.opacity(0.45))
            .buttonStyle(.plain)
        }
    }
}
