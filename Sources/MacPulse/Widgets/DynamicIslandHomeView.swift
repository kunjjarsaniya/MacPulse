import AppKit
import SwiftUI

// MARK: - Dynamic Island Home View (Now Playing & Quick Actions)

public struct DynamicIslandHomeView: View {
    @ObservedObject private var media = MediaManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    private var visualizerBarColor: Color {
        guard media.currentTrack.isPlaying else {
            return MacPulseColors.textQuaternary
        }
        return media.currentTrack.playerSource == "Spotify"
            ? MacPulseColors.spotifyGreen
            : MacPulseColors.appleMusicRed
    }
    
    private func visualizerBarHeight(at idx: Int) -> CGFloat {
        guard media.currentTrack.isPlaying else { return 4.0 }
        let level = media.visualizerLevels.indices.contains(idx) ? media.visualizerLevels[idx] : 0.3
        return max(4.0, 16.0 * level)
    }
    
    public var body: some View {
        HStack(spacing: MacPulseSpacing.lg) {
            mediaPlayerCard
                .frame(maxWidth: .infinity)
            
            actionStack
                .frame(width: 175)
        }
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    // MARK: - Quick Action Buttons Stack
    private var actionStack: some View {
        VStack(spacing: MacPulseSpacing.sm) {
            IslandActionButton(
                title: "Quit All Apps",
                icon: "sparkles",
                iconColor: MacPulseColors.appleYellow
            ) {
                media.quitAllApps()
                controller.triggerToast(title: "Apps Closed", subtitle: "All inactive apps terminated")
            }
            
            IslandActionButton(
                title: "Terminal",
                icon: "apple.terminal",
                iconColor: MacPulseColors.appleCyan,
                accessory: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(MacPulseColors.textTertiary)
                }
            ) {
                media.openTerminal()
            }
            
            IslandActionButton(
                title: "Mirror",
                icon: "web.camera",
                iconColor: MacPulseColors.appleGreen,
                accessory: {
                    Circle()
                        .fill(controller.showCameraMirror ? MacPulseColors.appleGreen : MacPulseColors.borderFocus)
                        .frame(width: 6, height: 6)
                }
            ) {
                withAnimation(MacPulseAnimations.islandSpring) {
                    controller.toggleCameraMirror()
                }
            }
        }
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
                    Circle().fill(
                        media.currentTrack.playerSource == "Spotify"
                            ? MacPulseColors.spotifyGreen
                            : MacPulseColors.appleMusicRed
                    )
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
