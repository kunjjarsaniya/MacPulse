import AppKit
import SwiftUI

// MARK: - Dynamic Island Notes View (Scratchpad Note Editor)

public struct DynamicIslandNotesView: View {
    @ObservedObject private var notes = NotesManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            // Text Editor Container
            ZStack(alignment: .topLeading) {
                if notes.noteText.isEmpty {
                    Text("Type quick notes, scratchpad thoughts, or drafts here...")
                        .font(MacPulseTypography.footnote)
                        .foregroundColor(MacPulseColors.textQuaternary)
                        .padding(.horizontal, MacPulseSpacing.md)
                        .padding(.vertical, MacPulseSpacing.md)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $notes.noteText)
                    .font(MacPulseTypography.footnote)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(MacPulseSpacing.xs)
            }
            .background(MacPulseColors.cardBackgroundSubtle)
            .clipShape(RoundedRectangle(cornerRadius: MacPulseRadius.md, style: .continuous))
            .frame(height: 84)
            
            // Footer
            IslandFooter(
                statusText: "\(notes.wordCount) words • \(notes.characterCount) chars"
            ) {
                HStack(spacing: MacPulseSpacing.lg) {
                    Button("Copy All") {
                        notes.copyAll()
                        controller.triggerToast(title: "Note Copied", subtitle: "Note text copied to clipboard")
                        HapticFeedback.playSoft()
                    }
                    .font(MacPulseTypography.captionSemibold)
                    .foregroundColor(Color.white.opacity(0.80))
                    .buttonStyle(.plain)
                    
                    Button("Clear") {
                        notes.clear()
                        HapticFeedback.playSoft()
                    }
                    .font(MacPulseTypography.caption)
                    .foregroundColor(Color.white.opacity(0.45))
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
}
