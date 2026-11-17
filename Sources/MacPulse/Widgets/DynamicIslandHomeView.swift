import AppKit
import SwiftUI

// MARK: - Dynamic Island Home View (Now Playing & Quick Actions)

public struct DynamicIslandHomeView: View {
    @ObservedObject private var media = MediaManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    private var visualizerBarColor: Color {
        guard media.currentTrack.isPlaying else {
            return Color.white.opacity(0.20)
        }
        return Color.white.opacity(0.85)
    }
    
    private func visualizerBarHeight(at idx: Int) -> CGFloat {
        guard media.currentTrack.isPlaying else { return 4.0 }
        let level = media.visualizerLevels.indices.contains(idx) ? media.visualizerLevels[idx] : 0.3
        return max(4.0, 16.0 * level)
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            mediaPlayerCard
                .frame(maxWidth: .infinity)
            
            actionStack
                .frame(width: 196)
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    // MARK: - Quick Action Buttons Stack (Monochromatic Apple Styling)
    private var actionStack: some View {
        VStack(spacing: 10) {
            // Row 1: Quit All Apps (Full Width)
            quickActionCard(
                title: "Quit All Apps",
                subtitle: "Quit background apps",
                icon: "sparkles"
            ) {
                media.quitAllApps()
                controller.triggerToast(title: "Apps Closed", subtitle: "All inactive apps terminated")
            }
            
            // Row 2: Split Action Row (Terminal & Camera Mirror - Pure Icon Style)
            HStack(spacing: 8) {
                iconActionTile(
                    icon: "apple.terminal",
                    isActive: false,
                    tooltip: "Terminal"
                ) {
                    media.openTerminal()
                    controller.triggerToast(title: "Terminal", subtitle: "Terminal launched")
                }
                
                iconActionTile(
                    icon: controller.showCameraMirror ? "web.camera.fill" : "web.camera",
                    isActive: controller.showCameraMirror,
                    tooltip: "Camera Mirror"
                ) {
                    withAnimation(MacPulseAnimations.islandSpring) {
                        controller.toggleCameraMirror()
                    }
                }
            }
            .frame(height: 52)
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    private func iconActionTile(
        icon: String,
        isActive: Bool = false,
        tooltip: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedback.playSoft()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.18) : MacPulseColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous)
                            .stroke(isActive ? Color.white.opacity(0.35) : MacPulseColors.hairline, lineWidth: 0.6)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 17.5, weight: .semibold))
                    .foregroundColor(isActive ? .white : Color.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
    
    private func quickActionCard(
        title: String,
        subtitle: String,
        icon: String,
        isExternal: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticFeedback.playSoft()
            action()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isExternal {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous)
                    .fill(MacPulseColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous)
                            .stroke(MacPulseColors.hairline, lineWidth: 0.6)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Media Player Card
    private var mediaPlayerCard: some View {
        IslandCard(
            cornerRadius: MacPulseRadius.media,
            fillColor: MacPulseColors.cardBackground,
            strokeColor: MacPulseColors.hairline
        ) {
            HStack(spacing: MacPulseSpacing.xl) {
                albumArtView
                trackDetailsAndControlsView
            }
            .padding(MacPulseSpacing.lg)
            .frame(height: MacPulseDimensions.contentHeight)
        }
    }
    
    private var albumArtView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let art = media.artworkImage {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: MacPulseDimensions.albumArtSize, height: MacPulseDimensions.albumArtSize)
                    .clipShape(RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: MacPulseRadius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1E1E24"), Color(hex: "#121216")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(MacPulseColors.textTertiary)
                }
                .frame(width: MacPulseDimensions.albumArtSize, height: MacPulseDimensions.albumArtSize)
            }
            
            Image(systemName: media.currentTrack.playerSource == "Spotify" ? "waveform" : "apple.logo")
                .font(MacPulseTypography.micro)
                .foregroundColor(.white)
                .padding(3.5)
                .background(
                    Circle().fill(Color.white.opacity(0.18))
                )
                .offset(x: 2, y: 2)
        }
    }
    
    private var trackDetailsAndControlsView: some View {
        VStack(alignment: .leading, spacing: MacPulseSpacing.xxs) {
            Text(media.currentTrack.title.isEmpty ? "No Media Playing" : media.currentTrack.title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(MacPulseColors.textPrimary)
                .lineLimit(1)
            
            Text(media.currentTrack.artist.isEmpty ? "Launch Music or Spotify" : media.currentTrack.artist)
                .font(MacPulseTypography.footnoteMedium)
                .foregroundColor(MacPulseColors.textSecondary)
                .lineLimit(1)
            
            // Audio Equalizer Spectrum Bars
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { idx in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(visualizerBarColor)
                        .frame(width: 3, height: visualizerBarHeight(at: idx))
                        .animation(.spring(response: 0.15, dampingFraction: 0.65), value: media.visualizerLevels[idx])
                }
            }
            .frame(height: 16)
            .padding(.vertical, 1)
            
            // Playback Controls
            HStack(spacing: MacPulseSpacing.gutter) {
                Button {
                    media.previousTrack()
                    HapticFeedback.playSoft()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(MacPulseTypography.subheadline)
                        .foregroundColor(MacPulseColors.textSecondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    media.playPause()
                    HapticFeedback.playSoft()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 26, height: 26)
                        Image(systemName: media.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .offset(x: media.currentTrack.isPlaying ? 0 : 0.8)
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    media.nextTrack()
                    HapticFeedback.playSoft()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(MacPulseTypography.subheadline)
                        .foregroundColor(MacPulseColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
