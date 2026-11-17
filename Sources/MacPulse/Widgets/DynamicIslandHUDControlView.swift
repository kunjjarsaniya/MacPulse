import AppKit
import SwiftUI

// MARK: - Dynamic Island HUD Control View (Native Sound & Brightness Controller)
// Faithfully matches Apple's Dynamic Island segmented slider HUD with ambient illumination.

public struct DynamicIslandHUDControlView: View {
    public let hudType: DynamicIslandHUDType
    
    @ObservedObject private var controls = SystemControlService.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    @State private var isDragging: Bool = false
    @State private var dragValue: Double? = nil
    
    private let totalBars: Int = 34
    private let barWidth: CGFloat = 3.5
    private let barHeight: CGFloat = 16.0
    private let barSpacing: CGFloat = 4.2
    
    public init(hudType: DynamicIslandHUDType) {
        self.hudType = hudType
    }
    
    private var currentValue: Double {
        if let dv = dragValue {
            return dv
        }
        return hudType == .volume ? controls.volume : controls.brightness
    }
    
    private var currentPercentage: Int {
        Int(round(currentValue * 100))
    }
    
    private var iconName: String {
        switch hudType {
        case .volume:
            if controls.isMuted || currentValue < 0.02 {
                return "speaker.slash.fill"
            } else if currentValue < 0.33 {
                return "speaker.wave.1.fill"
            } else if currentValue < 0.66 {
                return "speaker.wave.2.fill"
            } else {
                return "speaker.wave.3.fill"
            }
        case .brightness:
            if currentValue < 0.30 {
                return "sun.min.fill"
            } else {
                return "sun.max.fill"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header Row: Icon (Left), Percentage (Center), Close/Back (Right)
            HStack {
                // Large Active Icon
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 20, alignment: .leading)
                
                Spacer()
                
                // Centered Percentage Readout
                Text("\(currentPercentage)%")
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                
                Spacer()
                
                // Return / Dismiss Action
                Button {
                    controller.dismissHUD()
                    HapticFeedback.playSoft()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.45))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            // Segmented Horizontal Slider
            GeometryReader { geo in
                let availableWidth = geo.size.width
                let activeBarCount = Int(round(currentValue * Double(totalBars)))
                
                HStack(spacing: barSpacing) {
                    ForEach(0..<totalBars, id: \.self) { idx in
                        let isActive = idx < activeBarCount
                        Capsule()
                            .fill(isActive ? Color.white : Color.white.opacity(0.18))
                            .frame(width: barWidth, height: barHeight)
                            .shadow(color: isActive ? Color.white.opacity(0.45) : Color.clear, radius: 4, x: 0, y: 0)
                            .animation(.easeOut(duration: 0.12), value: activeBarCount)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let progress = calculateProgress(location: gesture.location.x, totalWidth: availableWidth)
                            dragValue = progress
                            applyValue(progress)
                        }
                        .onEnded { gesture in
                            let progress = calculateProgress(location: gesture.location.x, totalWidth: availableWidth)
                            dragValue = nil
                            applyValue(progress)
                            isDragging = false
                            HapticFeedback.playSoft()
                        }
                )
            }
            .frame(height: barHeight)
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: MacPulseDimensions.hudIslandSize.width, height: MacPulseDimensions.hudIslandSize.height)
    }
    
    private func calculateProgress(location: CGFloat, totalWidth: CGFloat) -> Double {
        // Slider occupies central portion with 14pt margin on each side
        let sliderWidth = totalWidth - 28.0
        let clampedX = min(max(location - 14.0, 0.0), sliderWidth)
        return Double(clampedX / sliderWidth)
    }
    
    private func applyValue(_ value: Double) {
        switch hudType {
        case .volume:
            controls.setVolume(value)
        case .brightness:
            controls.setBrightness(value)
        }
    }
}
