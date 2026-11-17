import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Dynamic Island Shelf View (File Staging Tray)

public struct DynamicIslandShelfView: View {
    @ObservedObject private var shelf = ShelfManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            if shelf.items.isEmpty {
                emptyStateDropZone
            } else {
                stagedFilesScrollArea
                footerBar
            }
        }
        .frame(height: MacPulseDimensions.contentHeight)
        .onDrop(of: [.fileURL, .data, .plainText], isTargeted: $shelf.isTargeted) { providers in
            shelf.loadProviders(providers)
            return true
        }
    }
    
    // MARK: - Empty Drop Zone
    private var emptyStateDropZone: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(MacPulseColors.appleCyan)
            
            Text("Drop Files to Stage")
                .font(MacPulseTypography.headline)
                .foregroundColor(MacPulseColors.textPrimary)
            
            Text("Drag files here to store temporarily, then drag them anywhere.")
                .font(MacPulseTypography.footnote)
                .foregroundColor(MacPulseColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: MacPulseRadius.shelf, style: .continuous)
                .strokeBorder(
                    shelf.isTargeted ? MacPulseColors.appleCyan : Color.white.opacity(0.12),
                    style: StrokeStyle(lineWidth: 1.0, dash: [4, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: MacPulseRadius.shelf, style: .continuous)
                        .fill(shelf.isTargeted ? MacPulseColors.appleCyan.opacity(0.08) : MacPulseColors.cardBackgroundSubtle)
                )
        )
    }
    
    // MARK: - Staged Files Area
    private var stagedFilesScrollArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MacPulseSpacing.md) {
                ForEach(shelf.items) { item in
                    stagedFileCard(for: item)
                }
            }
            .padding(.horizontal, MacPulseSpacing.xs)
        }
        .frame(height: 90)
    }
    
    private func stagedFileCard(for item: ShelfItem) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: MacPulseSpacing.xs) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
                
                Text(item.fileName)
                    .font(MacPulseTypography.footnoteMedium)
                    .foregroundColor(MacPulseColors.textPrimary)
                    .lineLimit(1)
                
                Text(item.fileSizeString)
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(MacPulseColors.textSecondary)
            }
            .padding(MacPulseSpacing.md)
            .frame(width: 76, height: 86)
            .background(
                RoundedRectangle(cornerRadius: MacPulseRadius.button, style: .continuous)
                    .fill(MacPulseColors.pillBackground)
            )
            .onDrag {
                shelf.makeItemProvider(for: item)
            }
            
            // Remove Badge Button
            Button {
                shelf.deleteItem(id: item.id)
                HapticFeedback.playSoft()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(MacPulseColors.textSecondary)
            }
            .buttonStyle(.plain)
            .offset(x: -4, y: 4)
        }
    }
    
    // MARK: - Footer
    private var footerBar: some View {
        IslandFooter(
            statusText: "\(shelf.items.count) item\(shelf.items.count == 1 ? "" : "s") staged"
        ) {
            Button("Clear All") {
                shelf.clearAll()
                HapticFeedback.playSoft()
            }
            .font(MacPulseTypography.caption)
            .foregroundColor(MacPulseColors.appleRed)
            .buttonStyle(.plain)
        }
    }
}
