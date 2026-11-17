import AppKit
import SwiftUI

// MARK: - Dynamic Island Clipboard View (Searchable Clipboard History with Rich Micro-Interactions)

public struct DynamicIslandClipboardView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    @State private var justCopiedId: UUID? = nil
    @State private var hoveredId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 8) {
            // Search Input Header
            searchHeader
            
            // Content Area / Scrollable History
            contentArea
            
            // Footer with Count & Clear Action
            footerView
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    // MARK: - 1. Search Header
    private var searchHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.40))
            
            TextField("Search clipboard history...", text: $clipboard.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.white)
            
            if !clipboard.searchText.isEmpty {
                Button {
                    clipboard.searchText = ""
                    HapticFeedback.playSoft()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }
    
    // MARK: - 2. Content Area
    @ViewBuilder
    private var contentArea: some View {
        if clipboard.filteredHistory.isEmpty {
            VStack(spacing: 4) {
                Spacer()
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 18))
                    .foregroundColor(Color.white.opacity(0.20))
                Text(clipboard.searchText.isEmpty ? "No clipboard history yet" : "No matches found")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.40))
                Spacer()
            }
            .frame(maxHeight: 62)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(clipboard.filteredHistory) { entry in
                        clipboardRow(for: entry)
                    }
                }
                .padding(.horizontal, 1)
            }
            .frame(maxHeight: 62)
        }
    }
    
    // MARK: - 3. Clipboard Item Row
    private func clipboardRow(for entry: ClipboardEntry) -> some View {
        let isCopied = justCopiedId == entry.id
        let isHovered = hoveredId == entry.id
        
        return HStack(spacing: 8) {
            // Text Preview
            Text(entry.content)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(isCopied ? .white : Color.white.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            // Visual Copy / Checkmark Button
            Button {
                copyEntryAction(entry)
            } label: {
                HStack(spacing: 4) {
                    if isCopied {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                        Text("Copied!")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8.5, weight: .semibold))
                            .foregroundColor(isHovered ? .white : Color.white.opacity(0.50))
                    }
                }
                .padding(.horizontal, isCopied ? 6 : 4)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isCopied ? Color.white.opacity(0.20) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            
            // Delete Item Button
            Button {
                deleteEntryAction(entry)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(isHovered ? Color(red: 1.0, green: 0.4, blue: 0.4) : Color.white.opacity(0.35))
                    .frame(width: 18, height: 18)
                    .background(
                        Circle().fill(isHovered ? Color.white.opacity(0.06) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isCopied ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.04)))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isCopied ? Color.white.opacity(0.25) : Color.clear, lineWidth: 0.6)
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredId = hovering ? entry.id : nil
        }
        .onTapGesture {
            copyEntryAction(entry)
        }
        .animation(.easeInOut(duration: 0.15), value: isCopied)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
    
    // MARK: - Actions with Toasts & Haptics
    private func copyEntryAction(_ entry: ClipboardEntry) {
        clipboard.copyEntry(entry)
        HapticFeedback.playSoft()
        
        withAnimation {
            justCopiedId = entry.id
        }
        
        controller.triggerToast(
            icon: "doc.on.doc.fill",
            title: "Copied!",
            subtitle: "Copied to clipboard"
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if self.justCopiedId == entry.id {
                withAnimation {
                    self.justCopiedId = nil
                }
            }
        }
    }
    
    private func deleteEntryAction(_ entry: ClipboardEntry) {
        clipboard.deleteEntry(id: entry.id)
        HapticFeedback.playSoft()
        
        controller.triggerToast(
            icon: "trash.fill",
            title: "Deleted",
            subtitle: "Removed from clipboard"
        )
    }
    
    // MARK: - 4. Footer View
    private var footerView: some View {
        HStack {
            Text("\(clipboard.history.count) items recorded")
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.35))
            
            Spacer()
            
            if !clipboard.history.isEmpty {
                Button {
                    clipboard.clearHistory()
                    HapticFeedback.playSoft()
                    controller.triggerToast(
                        icon: "trash.fill",
                        title: "History Cleared",
                        subtitle: "All clipboard items removed"
                    )
                } label: {
                    Text("Clear All")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}
