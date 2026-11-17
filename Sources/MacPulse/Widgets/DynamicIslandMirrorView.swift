import AppKit
import SwiftUI

public struct DynamicIslandMirrorView: View {
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            CameraPreviewView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                )
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    controller.toggleCameraMirror()
                }
                playSoftHaptic()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.white.opacity(0.85))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 118)
    }
}
