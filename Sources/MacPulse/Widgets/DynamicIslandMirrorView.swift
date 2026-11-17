import AppKit
import SwiftUI

// MARK: - Dynamic Island Mirror View (Webcam Mirror Feed)

public struct DynamicIslandMirrorView: View {
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            CameraPreviewView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: MacPulseRadius.shelf, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MacPulseRadius.shelf, style: .continuous)
                        .stroke(MacPulseColors.borderMedium, lineWidth: 0.8)
                )
            
            Button {
                withAnimation(MacPulseAnimations.islandSpring) {
                    controller.toggleCameraMirror()
                }
                HapticFeedback.playSoft()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MacPulseColors.textPrimary)
                    .padding(MacPulseSpacing.md)
            }
            .buttonStyle(.plain)
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
}
