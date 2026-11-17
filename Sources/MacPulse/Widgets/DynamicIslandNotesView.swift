import AppKit
import SwiftUI

public struct DynamicIslandNotesView: View {
    @ObservedObject private var notes = NotesManager.shared
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
            // Text Editor with sleek placeholder
            ZStack(alignment: .topLeading) {
                if notes.noteText.isEmpty {
                    Text("Type quick notes, scratchpad thoughts, or drafts here...")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color.white.opacity(0.30))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $notes.noteText)
                    .font(.system(size: 10.5))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
            }
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(height: 84)
            
            // Footer
            HStack {
                Text("\(notes.wordCount) words • \(notes.characterCount) chars")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))
                Spacer()
                Button("Copy All") {
                    notes.copyAll()
                    controller.triggerToast(title: "Note Copied", subtitle: "Note text copied to clipboard")
                    playSoftHaptic()
                }
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundColor(Color(hex: "#38BDF8"))
                .buttonStyle(.plain)
                
                Button("Clear") {
                    notes.clear()
                    playSoftHaptic()
                }
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(Color(hex: "#FF453A"))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 118)
    }
}
