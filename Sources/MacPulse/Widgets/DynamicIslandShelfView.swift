import AppKit
import SwiftUI
import UniformTypeIdentifiers

public struct DynamicIslandShelfView: View {
    @ObservedObject private var shelf = ShelfManager.shared
    
    public init() {}
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            if shelf.items.isEmpty {
                // Empty State Drop Zone
                VStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "#38BDF8"))
                    Text("Drop Files to Stage")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text("Drag files here to store temporarily, then drag them anywhere.")
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.50))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(shelf.isTargeted ? Color(hex: "#38BDF8") : Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.03)))
                )
            } else {
                // Staged Files Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shelf.items) { item in
                            ZStack(alignment: .topTrailing) {
                                VStack(spacing: 4) {
                                    Image(nsImage: item.icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 38, height: 38)
                                    Text(item.fileName)
                                        .font(.system(size: 9.5, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(item.fileSizeString)
                                        .font(.system(size: 8, weight: .regular, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.50))
                                }
                                .padding(8)
                                .frame(width: 76, height: 86)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
                                .onDrag {
                                    shelf.makeItemProvider(for: item)
                                }
                                
                                // Delete button
                                Button {
                                    shelf.deleteItem(id: item.id)
                                    playSoftHaptic()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.70))
                                }
                                .buttonStyle(.plain)
                                .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 90)
                
                // Footer
                HStack {
                    Text("\(shelf.items.count) item\(shelf.items.count == 1 ? "" : "s") staged")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.50))
                    Spacer()
                    Button("Clear All") {
                        shelf.clearAll()
                        playSoftHaptic()
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Color(hex: "#FF453A"))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(height: 118)
        .onDrop(of: [.fileURL, .data, .plainText], isTargeted: $shelf.isTargeted) { providers in
            shelf.loadProviders(providers)
            return true
        }
    }
}
