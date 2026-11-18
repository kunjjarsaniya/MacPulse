import AppKit
import SwiftUI

// MARK: - Dynamic Island Home View (Dedicated Spotify & Minimalist Monochromatic Styling)

public struct DynamicIslandHomeView: View {
    @ObservedObject private var media = MediaManager.shared
    @ObservedObject private var controller = DynamicIslandController.shared
    
    @State private var isQuitHovered: Bool = false
    @State private var isTerminalHovered: Bool = false
    @State private var isMirrorHovered: Bool = false
    @State private var isOpenSpotifyHovered: Bool = false
    
    private let artSize: CGFloat = 88
    
    public init() {}
    
    private var visualizerBarColor: Color {
        guard media.currentTrack.isPlaying else {
            return Color(hex: "#1DB954").opacity(0.35)
        }
        return Color(hex: "#1ED760")
    }
    
    private func visualizerBarHeight(at idx: Int) -> CGFloat {
        guard media.currentTrack.isPlaying else { return 3.5 }
        let level = media.visualizerLevels.indices.contains(idx) ? media.visualizerLevels[idx] : 0.35
        return max(3.5, 15.0 * level)
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // 1. Left: Dedicated Spotify Player Section (Perfect Alignment with Artwork)
            spotifyPlayerSection
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 2. Center-Left: Subtle Hairline Divider
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 72)
                .padding(.horizontal, 14)
            
            // 3. Center-Right: Two Stacked Capsule Action Buttons
            middleActionsSection
                .frame(width: 144)
            
            Spacer(minLength: 12)
            
            // 4. Right: Large Circular Mirror Button
            circularMirrorButton
                .frame(width: 74)
        }
        .padding(.horizontal, 16)
        .frame(height: MacPulseDimensions.contentHeight)
    }
    
    // MARK: - 1. Spotify Player Section (Mathematically Flush Top & Bottom)
    private var spotifyPlayerSection: some View {
        HStack(alignment: .center, spacing: 14) {
            spotifyArtView
                .frame(width: artSize, height: artSize)
            
            spotifyDetailsAndControlsView
                .frame(height: artSize)
        }
    }
    
    // MARK: - Artwork with Live Glow & Spotify Badge
    private var spotifyArtView: some View {
        let isPlaying = media.currentTrack.isPlaying
        let hasActiveTrack = media.hasMedia && !media.currentTrack.title.isEmpty
        
        return ZStack(alignment: .bottomTrailing) {
            // Subtle ambient playing glow
            if hasActiveTrack && isPlaying {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#1DB954").opacity(0.20))
                    .frame(width: artSize, height: artSize)
                    .blur(radius: 8)
            }
            
            // Centered artwork content (Always rock-solid 88x88pt for mathematical alignment)
            Group {
                if hasActiveTrack, let art = media.artworkImage {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: artSize, height: artSize)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                } else {
                    // Dedicated Spotify Squircle Placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#16161C"), Color(hex: "#0E0E12")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.6)
                            )
                        
                        // Centered Spotify Logo with Subtle Glow
                        SpotifyLogoView(size: 34)
                    }
                    .frame(width: artSize, height: artSize)
                }
            }
            
            // Spotify Badge in Bottom-Right Corner
            if hasActiveTrack {
                SpotifyBadgeView(size: 24)
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: artSize, height: artSize)
    }
    
    // MARK: - Track Details & Controls (Perfect Vertical Alignment & Live Equalizer)
    private var spotifyDetailsAndControlsView: some View {
        let hasActiveTrack = media.hasMedia && !media.currentTrack.title.isEmpty
        
        return VStack(alignment: .leading, spacing: 0) {
            if hasActiveTrack {
                // Top: Text Column (Top-aligned with Album Art)
                VStack(alignment: .leading, spacing: 2) {
                    // Line 1: Track Title (Bold White, 14.5pt)
                    Text(media.currentTrack.title)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Line 2: Album Title (Medium 11.5pt, ~70% Opacity)
                    Text(albumOrSubtitleText)
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.70))
                        .lineLimit(1)
                    
                    // Line 3: Artist Name (Medium 10.5pt, ~48% Opacity)
                    Text(media.currentTrack.artist.isEmpty ? "Spotify" : media.currentTrack.artist)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.48))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                // Bottom: Playback Controls & Live Equalizer (Bottom-aligned with Album Art)
                HStack(spacing: 12) {
                    // Controls: |◀   || / ▶   ▶|
                    HStack(spacing: 14) {
                        // Previous Track (|◀) - Leading aligned to match text column
                        Button {
                            media.previousTrack()
                            HapticFeedback.playSoft()
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.85))
                                .frame(width: 16, height: 20, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Play/Pause Button (|| or ▶)
                        Button {
                            media.playPause()
                            HapticFeedback.playSoft()
                        } label: {
                            Image(systemName: media.currentTrack.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Next Track (▶|)
                        Button {
                            media.nextTrack()
                            HapticFeedback.playSoft()
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.85))
                                .frame(width: 20, height: 20)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Live Playing Equalizer Visualizer Animation!
                    if media.currentTrack.isPlaying {
                        HStack(spacing: 2.5) {
                            ForEach(0..<4, id: \.self) { idx in
                                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                    .fill(visualizerBarColor)
                                    .frame(width: 2.5, height: visualizerBarHeight(at: idx))
                                    .animation(.spring(response: 0.16, dampingFraction: 0.65), value: media.visualizerLevels[idx])
                            }
                        }
                        .frame(height: 16)
                        .padding(.leading, 3)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.75), value: media.currentTrack.isPlaying)
            } else {
                // Dedicated Spotify Idle State
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spotify")
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Not Playing")
                        .font(.system(size: 11.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.65))
                        .lineLimit(1)
                    
                    Text("Play your favorite music")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.40))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
                
                // Single Sleek Spotify Capsule Button
                Button {
                    HapticFeedback.playSoft()
                    media.launchSpotify()
                    controller.triggerToast(icon: "waveform", title: "Spotify", subtitle: "Opening Spotify")
                } label: {
                    HStack(spacing: 6) {
                        SpotifyMiniIcon(size: 14)
                        
                        Text("Open Spotify")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(
                        Capsule()
                            .fill(isOpenSpotifyHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.10))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isOpenSpotifyHovered ? Color(hex: "#1DB954").opacity(0.55) : Color.white.opacity(0.12),
                                        lineWidth: 0.6
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .onHover { isOpenSpotifyHovered = $0 }
            }
        }
        .frame(height: artSize)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var albumOrSubtitleText: String {
        let title = media.currentTrack.title
        let album = media.currentTrack.album
        let artist = media.currentTrack.artist
        
        if !album.isEmpty && album.caseInsensitiveCompare(title) != .orderedSame {
            return album
        }
        if !artist.isEmpty {
            return "Single • \(artist)"
        }
        return "Spotify"
    }
    
    // MARK: - 3. Center Section: Two Stacked Capsule Buttons (Quit All Apps & Terminal)
    private var middleActionsSection: some View {
        VStack(spacing: 10) {
            // Row 1: Quit All Apps Capsule
            Button {
                HapticFeedback.playSoft()
                media.quitAllApps()
                controller.triggerToast(icon: "sparkles", title: "Apps Closed", subtitle: "All inactive apps terminated")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#FFD700"))
                    
                    Text("Quit All Apps")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Capsule()
                        .fill(isQuitHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(isQuitHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.12), lineWidth: 0.6)
                        )
                )
            }
            .buttonStyle(.plain)
            .onHover { isQuitHovered = $0 }
            
            // Row 2: Terminal Capsule
            Button {
                HapticFeedback.playSoft()
                media.openTerminal()
                controller.triggerToast(icon: "apple.terminal", title: "Terminal", subtitle: "Terminal launched")
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.terminal")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Terminal")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    Capsule()
                        .fill(isTerminalHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.10))
                        .overlay(
                            Capsule()
                                .stroke(isTerminalHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.12), lineWidth: 0.6)
                        )
                )
            }
            .buttonStyle(.plain)
            .onHover { isTerminalHovered = $0 }
        }
    }
    
    // MARK: - 4. Right Section: Large Circular Mirror Button (Camera + Mirror Label)
    private var circularMirrorButton: some View {
        Button {
            HapticFeedback.playSoft()
            withAnimation(MacPulseAnimations.islandSpring) {
                controller.toggleCameraMirror()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        controller.showCameraMirror
                            ? Color.white.opacity(0.22)
                            : (isMirrorHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.10))
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                controller.showCameraMirror
                                    ? Color.white.opacity(0.40)
                                    : (isMirrorHovered ? Color.white.opacity(0.24) : Color.white.opacity(0.12)),
                                lineWidth: controller.showCameraMirror ? 1.0 : 0.6
                            )
                    )
                
                VStack(spacing: 4) {
                    Image(systemName: controller.showCameraMirror ? "web.camera.fill" : "web.camera")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Mirror")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }
            }
            .frame(width: 72, height: 72)
        }
        .buttonStyle(.plain)
        .onHover { isMirrorHovered = $0 }
        .help("Toggle Camera Mirror")
    }
}

// MARK: - Spotify Badge View (Squircle with 3 Curved Arcs & Cutout Notch)

public struct SpotifyBadgeView: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 24) {
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
                .stroke(Color.black, lineWidth: 2.0)
        )
    }
}

// MARK: - Spotify Logo View (For Idle Placeholder)

public struct SpotifyLogoView: View {
    public let size: CGFloat
    
    public init(size: CGFloat = 34) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Ambient Green Glow
            Circle()
                .fill(Color(hex: "#1DB954").opacity(0.28))
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: 6)
            
            // Green Circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1ED760"), Color(hex: "#1DB954")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // 3 Dark Arcs
            VStack(spacing: size * 0.08) {
                SpotifyWaveArc(width: size * 0.54, strokeWidth: size * 0.095, archFactor: 0.26)
                SpotifyWaveArc(width: size * 0.44, strokeWidth: size * 0.085, archFactor: 0.24)
                SpotifyWaveArc(width: size * 0.34, strokeWidth: size * 0.075, archFactor: 0.22)
            }
            .rotationEffect(.degrees(-12))
            .offset(x: size * 0.02, y: size * 0.02)
        }
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
