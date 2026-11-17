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
        guard media.currentTrack.isPlaying else { return 3.5 }
        let level = media.visualizerLevels.indices.contains(idx) ? media.visualizerLevels[idx] : 0.35
        return max(3.5, 15.0 * level)
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
                controller.triggerToast(icon: "sparkles", title: "Apps Closed", subtitle: "All inactive apps terminated")
            }
            
            // Row 2: Split Action Row (Terminal & Camera Mirror - Pure Icon Style)
            HStack(spacing: 8) {
                iconActionTile(
                    icon: "apple.terminal",
                    isActive: false,
                    tooltip: "Terminal"
                ) {
                    media.openTerminal()
                    controller.triggerToast(icon: "apple.terminal", title: "Terminal", subtitle: "Terminal launched")
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
    
    // MARK: - Media Player Card (Matching Apple Dynamic Island Reference)
    private var mediaPlayerCard: some View {
        IslandCard(
            cornerRadius: MacPulseRadius.media,
            fillColor: MacPulseColors.cardBackground,
            strokeColor: MacPulseColors.hairline
        ) {
            HStack(spacing: 16) {
                albumArtView
                trackDetailsAndControlsView
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(height: MacPulseDimensions.contentHeight)
        }
    }
    
    // MARK: - Album Artwork with Live Playing Glow & App Source Badge
    private var albumArtView: some View {
        let isPlaying = media.currentTrack.isPlaying
        let artSize: CGFloat = 82
        
        return ZStack(alignment: .bottomTrailing) {
            // Subtle ambient playing glow
            if isPlaying {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: artSize, height: artSize)
                    .blur(radius: 6)
            }
            
            // Artwork image or minimal fallback squircle
            Group {
                if let art = media.artworkImage {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1E1E24"), Color(hex: "#121216")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                            )
                        
                        Image(systemName: media.currentTrack.playerSource == "Spotify" ? "waveform" : "music.note")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.35))
                    }
                    .frame(width: artSize, height: artSize)
                }
            }
            .scaleEffect(isPlaying ? 1.0 : 0.94)
            .animation(.spring(response: 0.32, dampingFraction: 0.74), value: isPlaying)
            
            // App Source Badge (Spotify Green Squircle / Apple Music Red Squircle with cutout notch)
            if media.hasMedia && !media.currentTrack.title.isEmpty {
                if media.currentTrack.playerSource == "Spotify" {
                    SpotifyBadgeView(size: 21)
                        .offset(x: 2, y: 2)
                } else {
                    AppleMusicBadgeView(size: 21)
                        .offset(x: 2, y: 2)
                }
            }
        }
        .frame(width: artSize, height: artSize)
    }
    
    // MARK: - Track Details & Controls (3-Tier Typography & Monochromatic Icons)
    private var trackDetailsAndControlsView: some View {
        VStack(alignment: .leading, spacing: 2.5) {
            // Line 1: Track Title (Bold White)
            Text(media.currentTrack.title.isEmpty ? "No Media Playing" : media.currentTrack.title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Line 2: Album Title (Medium, Muted White)
            Text(albumText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.70))
                .lineLimit(1)
            
            // Line 3: Artist Name (Medium, Dim Gray)
            Text(artistText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.45))
                .lineLimit(1)
            
            Spacer(minLength: 2)
            
            // Bottom Row: Monochromatic Playback Controls & Live Equalizer
            if media.hasMedia && !media.currentTrack.title.isEmpty {
                HStack(spacing: 16) {
                    // Previous Track Button
                    Button {
                        media.previousTrack()
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Play/Pause Button (Clean icon without circular background, matching reference)
                    Button {
                        media.playPause()
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: media.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Next Track Button
                    Button {
                        media.nextTrack()
                        HapticFeedback.playSoft()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.85))
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer(minLength: 4)
                    
                    // Live 4-Bar Equalizer Visualizer
                    HStack(spacing: 2.5) {
                        ForEach(0..<4, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(visualizerBarColor)
                                .frame(width: 2.5, height: visualizerBarHeight(at: idx))
                                .animation(.spring(response: 0.16, dampingFraction: 0.65), value: media.visualizerLevels[idx])
                        }
                    }
                    .frame(height: 16)
                    .padding(.trailing, 2)
                }
            } else {
                // Idle state: Quick launcher pills for Spotify & Music
                HStack(spacing: 8) {
                    Button {
                        media.launchSpotify()
                        controller.triggerToast(icon: "waveform", title: "Spotify", subtitle: "Opening Spotify")
                    } label: {
                        HStack(spacing: 5) {
                            SpotifyMiniIcon(size: 12)
                            Text("Spotify")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        media.launchMusic()
                        controller.triggerToast(icon: "music.note", title: "Apple Music", subtitle: "Opening Music")
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "music.note")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(Color(hex: "#FA2D48"))
                            Text("Music")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var albumText: String {
        if !media.currentTrack.album.isEmpty {
            return media.currentTrack.album
        }
        if !media.currentTrack.artist.isEmpty {
            return media.currentTrack.artist
        }
        return "Launch Spotify or Music"
    }
    
    private var artistText: String {
        if !media.currentTrack.artist.isEmpty {
            return media.currentTrack.artist
        }
        return "MacPulse Audio"
    }
}

// MARK: - Spotify Badge View (Squircle with 3 Curved Arcs & Cutout Notch)

public struct SpotifyBadgeView: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 21) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Spotify Green Squircle
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1ED760"), Color(hex: "#1DB954")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Spotify 3 Sound Arcs (Tilted slightly like official Spotify brand)
            VStack(spacing: size * 0.08) {
                SpotifyWaveArc(width: size * 0.52, strokeWidth: size * 0.095, archFactor: 0.26)
                SpotifyWaveArc(width: size * 0.42, strokeWidth: size * 0.085, archFactor: 0.24)
                SpotifyWaveArc(width: size * 0.32, strokeWidth: size * 0.080, archFactor: 0.22)
            }
            .rotationEffect(.degrees(-12))
            .offset(x: size * 0.02, y: size * 0.02)
        }
        .frame(width: size, height: size)
        .overlay(
            // Cutout notch stroke
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.black, lineWidth: 1.8)
        )
    }
}

// MARK: - Apple Music Badge View (Squircle with White Note & Cutout Notch)

public struct AppleMusicBadgeView: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 21) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Apple Music Red Gradient Squircle
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FA2D48"), Color(hex: "#D61633")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // White Music Note
            Image(systemName: "music.note")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            // Cutout notch stroke
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.black, lineWidth: 1.8)
        )
    }
}

// MARK: - Spotify Sound Wave Arc Shape

public struct SpotifyWaveArc: View {
    public let width: CGFloat
    public let strokeWidth: CGFloat
    public let archFactor: CGFloat
    
    public init(width: CGFloat, strokeWidth: CGFloat, archFactor: CGFloat) {
        self.width = width
        self.strokeWidth = strokeWidth
        self.archFactor = archFactor
    }
    
    public var body: some View {
        Path { path in
            let arch = width * archFactor
            path.move(to: CGPoint(x: 0, y: arch))
            path.addQuadCurve(
                to: CGPoint(x: width, y: arch * 0.85),
                control: CGPoint(x: width * 0.50, y: 0)
            )
        }
        .stroke(Color.black.opacity(0.92), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        .frame(width: width, height: max(2, width * archFactor))
    }
}

// MARK: - Mini Spotify Icon for Buttons

public struct SpotifyMiniIcon: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 12) {
        self.size = size
    }
    
    public var body: some View {
        Circle()
            .fill(Color(hex: "#1DB954"))
            .frame(width: size, height: size)
            .overlay(
                VStack(spacing: size * 0.08) {
                    SpotifyWaveArc(width: size * 0.52, strokeWidth: size * 0.10, archFactor: 0.24)
                    SpotifyWaveArc(width: size * 0.42, strokeWidth: size * 0.09, archFactor: 0.22)
                }
                .rotationEffect(.degrees(-12))
                .offset(y: size * 0.04)
            )
    }
}
