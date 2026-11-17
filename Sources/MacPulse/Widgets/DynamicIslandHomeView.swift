import AppKit
import SwiftUI

public struct DynamicIslandHomeView: View {
    @ObservedObject private var media = MediaManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    public init() {}
    
    private var visualizerBarColor: Color {
        if !media.currentTrack.isPlaying {
            return Color.white.opacity(0.20)
        }
        return media.currentTrack.playerSource == "Spotify" ? Color(hex: "#1DB954") : Color(hex: "#FA2D48")
    }
    
    private func visualizerBarHeight(at idx: Int) -> CGFloat {
        if !media.currentTrack.isPlaying { return 4.0 }
        let level = media.visualizerLevels.indices.contains(idx) ? media.visualizerLevels[idx] : 0.3
        return max(4.0, 16.0 * level)
    }
    
    private func playSoftHaptic() {
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            mediaPlayerCard
                .frame(maxWidth: .infinity)
            
            actionStack
                .frame(width: 175)
        }
        .frame(height: 118)
    }
    
    private var actionStack: some View {
        VStack(spacing: 7) {
            Button {
                media.quitAllApps()
                controller.triggerToast(title: "Apps Closed", subtitle: "All inactive apps terminated")
                playSoftHaptic()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#FFD60A"))
                    Text("Quit All Apps")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
            
            Button {
                media.openTerminal()
                playSoftHaptic()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "apple.terminal")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#38BDF8"))
                    Text("Terminal")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    controller.toggleCameraMirror()
                }
                playSoftHaptic()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "web.camera")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color(hex: "#30D158"))
                    Text("Mirror")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(controller.showCameraMirror ? Color(hex: "#30D158") : Color.white.opacity(0.20))
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var mediaPlayerCard: some View {
        HStack(spacing: 12) {
            albumArtView
            trackDetailsAndControlsView
        }
        .padding(10)
        .frame(height: 118)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                )
        )
    }
    
    private var albumArtView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let art = media.artworkImage {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1E1E24"), Color(hex: "#121216")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .frame(width: 72, height: 72)
            }
            
            Image(systemName: media.currentTrack.playerSource == "Spotify" ? "waveform" : "apple.logo")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white)
                .padding(3.5)
                .background(Circle().fill(media.currentTrack.playerSource == "Spotify" ? Color(hex: "#1DB954") : Color(hex: "#FA2D48")))
                .offset(x: 2, y: 2)
        }
    }
    
    private var trackDetailsAndControlsView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(media.currentTrack.title.isEmpty ? "No Media Playing" : media.currentTrack.title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Text(media.currentTrack.artist.isEmpty ? "Launch Music or Spotify" : media.currentTrack.artist)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.white.opacity(0.60))
                .lineLimit(1)
            
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
            
            HStack(spacing: 14) {
                Button {
                    media.previousTrack()
                    playSoftHaptic()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .buttonStyle(.plain)
                
                Button {
                    media.playPause()
                    playSoftHaptic()
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
                    playSoftHaptic()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
