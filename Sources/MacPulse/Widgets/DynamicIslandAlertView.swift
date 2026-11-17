import AppKit
import SwiftUI

// MARK: - Dynamic Island Alert Banner / HUD (Apple-Grade Animated Alert View)

public struct DynamicIslandAlertView: View {
    public let alert: DynamicIslandAlertItem
    @ObservedObject private var controller = DynamicIslandController.shared
    @State private var isPulsing: Bool = false
    
    public init(alert: DynamicIslandAlertItem) {
        self.alert = alert
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Glowing Pulsing Icon Squircle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 38, height: 38)
                
                Circle()
                    .stroke(
                        Color.white.opacity(isPulsing ? 0.45 : 0.15),
                        lineWidth: 1.2
                    )
                    .frame(width: 38, height: 38)
                    .scaleEffect(isPulsing ? 1.08 : 1.0)
                
                Image(systemName: alert.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
            
            // Text Details
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(MacPulseColors.textPrimary)
                    .lineLimit(1)
                
                Text(alert.subtitle)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(MacPulseColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            // Action & Dismiss Controls
            HStack(spacing: 8) {
                if let action = alert.actionTitle {
                    Button {
                        HapticFeedback.playSoft()
                        controller.handleAlertAction()
                    } label: {
                        Text(action)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
                
                // Dismiss Button
                Button {
                    HapticFeedback.playSoft()
                    controller.dismissAlert()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.70))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 6)
        .onAppear {
            isPulsing = true
        }
    }
}
