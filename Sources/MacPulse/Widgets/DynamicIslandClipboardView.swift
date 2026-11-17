import AppKit
import SwiftUI

public struct DynamicIslandClipboardView: View {
    @ObservedObject private var clipboard = ClipboardManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            searchBar
            contentArea
            footerView
        }
        .frame(height: 118)
    }
    
    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.40))
            TextField("Search clipboard history...", text: $clipboard.searchText)
                .font(.system(size: 10))
                .textFieldStyle(.plain)
                .foregroundColor(.white)
            if !clipboard.searchText.isEmpty {
                Button {
                    clipboard.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.06)))
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if clipboard.filteredHistory.isEmpty {
            VStack {
                Spacer()
                Text("No clipboard history")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.40))
                Spacer()
            }
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 4) {
                    ForEach(clipboard.filteredHistory) { entry in
                        clipboardRow(for: entry)
                    }
                }
            }
            .frame(maxHeight: 70)
        }
    }
    
    private func clipboardRow(for entry: ClipboardEntry) -> some View {
        HStack(spacing: 6) {
            Text(entry.content)
                .font(.system(size: 9.5))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                clipboard.copyEntry(entry)
                controller.triggerToast(title: "Copied!", subtitle: "Item copied to clipboard")
                playSoftHaptic()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: "#38BDF8"))
                    .padding(4)
                    .background(Circle().fill(Color(hex: "#38BDF8").opacity(0.12)))
            }
            .buttonStyle(.plain)
            
            Button {
                clipboard.deleteEntry(id: entry.id)
                playSoftHaptic()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.40))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.04)))
    }
    
    private var footerView: some View {
        HStack {
            Text("\(clipboard.history.count) items recorded")
                .font(.system(size: 8.5))
                .foregroundColor(Color.white.opacity(0.45))
            Spacer()
            Button("Clear History") {
                clipboard.clearHistory()
                playSoftHaptic()
            }
            .font(.system(size: 8.5, weight: .medium))
            .foregroundColor(Color(hex: "#FF453A"))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
}
