import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Media Item Information
public struct MediaItem: Equatable, Sendable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let playerSource: String
    
    public init(title: String = "", artist: String = "", album: String = "", isPlaying: Bool = false, playerSource: String = "Music") {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.playerSource = playerSource
    }
}

// MARK: - Media Manager
@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public private(set) var currentTrack: MediaItem = MediaItem()
    @Published public private(set) var artworkImage: NSImage? = nil
    @Published public private(set) var visualizerLevels: [CGFloat] = [0.25, 0.45, 0.85, 0.60, 0.35]
    @Published public private(set) var hasMedia: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var pollTimer: Timer?
    private var visualizerTimer: Timer?
    private var artworkCache: [String: NSImage] = [:]
    private var isUpdating: Bool = false
    
    private init() {
        setupObservers()
        startPeriodicPolling()
        startVisualizerTimer()
        refreshNowPlaying()
    }
    
    deinit {
        pollTimer?.invalidate()
        visualizerTimer?.invalidate()
    }
    
    // MARK: - Observers
    private func setupObservers() {
        let center = DistributedNotificationCenter.default()
        
        center.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNowPlaying()
            }
        }
        
        center.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshNowPlaying()
            }
        }
    }
    
    private func startPeriodicPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNowPlaying()
            }
        }
    }
    
    private func startVisualizerTimer() {
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.currentTrack.isPlaying else { return }
                self.visualizerLevels = (0..<5).map { _ in
                    CGFloat.random(in: 0.15...0.95)
                }
            }
        }
    }
    
    // MARK: - Fetch Now Playing via AppleScript
    public func refreshNowPlaying() {
        guard !isUpdating else { return }
        isUpdating = true
        
        Task.detached(priority: .userInitiated) {
            let scriptText = """
            if application "Music" is running then
                tell application "Music"
                    set pState to player state as string
                    if pState is "playing" then
                        try
                            set trName to name of current track
                            set trArtist to artist of current track
                            set trAlbum to album of current track
                            return "playing:::" & trName & ":::" & trArtist & ":::" & trAlbum & ":::Music"
                        on error
                            return "paused:::::::Music"
                        end try
                    else if pState is "paused" then
                        try
                            set trName to name of current track
                            set trArtist to artist of current track
                            set trAlbum to album of current track
                            return "paused:::" & trName & ":::" & trArtist & ":::" & trAlbum & ":::Music"
                        on error
                            return "stopped:::::::Music"
                        end try
                    else
                        return "stopped:::::::Music"
                    end if
                end tell
            else if application "Spotify" is running then
                tell application "Spotify"
                    set pState to player state as string
                    if pState is "playing" then
                        try
                            set trName to name of current track
                            set trArtist to artist of current track
                            set trAlbum to album of current track
                            return "playing:::" & trName & ":::" & trArtist & ":::" & trAlbum & ":::Spotify"
                        on error
                            return "paused:::::::Spotify"
                        end try
                    else if pState is "paused" then
                        try
                            set trName to name of current track
                            set trArtist to artist of current track
                            set trAlbum to album of current track
                            return "paused:::" & trName & ":::" & trArtist & ":::" & trAlbum & ":::Spotify"
                        on error
                            return "stopped:::::::Spotify"
                        end try
                    else
                        return "stopped:::::::Spotify"
                    end if
                end tell
            else
                return "none"
            end if
            """
            
            var error: NSDictionary?
            let script = NSAppleScript(source: scriptText)
            let result = script?.executeAndReturnError(&error).stringValue ?? "none"
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isUpdating = false
                self.processScriptResult(result)
            }
        }
    }
    
    private func processScriptResult(_ result: String) {
        guard result != "none" else {
            if hasMedia {
                currentTrack = MediaItem()
                artworkImage = nil
                hasMedia = false
            }
            return
        }
        
        let parts = result.components(separatedBy: ":::")
        guard parts.count >= 5 else { return }
        
        let state = parts[0]
        let name = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let album = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
        let source = parts[4].trimmingCharacters(in: .whitespacesAndNewlines)
        let isPlaying = (state == "playing")
        
        if name.isEmpty && artist.isEmpty {
            self.hasMedia = false
            self.currentTrack = MediaItem(isPlaying: false, playerSource: source)
            self.artworkImage = nil
            return
        }
        
        let newTrack = MediaItem(
            title: name,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            playerSource: source
        )
        
        let trackChanged = (self.currentTrack.title != newTrack.title || self.currentTrack.artist != newTrack.artist)
        self.currentTrack = newTrack
        self.hasMedia = true
        
        if trackChanged || self.artworkImage == nil {
            fetchArtwork(for: newTrack)
        }
    }
    
    // MARK: - Artwork Resolution
    private func fetchArtwork(for track: MediaItem) {
        guard !track.title.isEmpty else { return }
        let cacheKey = "\(track.title)|\(track.artist)"
        if let cached = artworkCache[cacheKey] {
            self.artworkImage = cached
            return
        }
        
        Task.detached(priority: .utility) {
            let query = "\(track.title) \(track.artist)".trimmingCharacters(in: .whitespacesAndNewlines)
            guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=song&limit=1") else {
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let results = json["results"] as? [[String: Any]],
                      let first = results.first,
                      let artUrlString = first["artworkUrl100"] as? String else {
                    return
                }
                
                let highRes = artUrlString.replacingOccurrences(of: "100x100", with: "600x600")
                guard let highResUrl = URL(string: highRes) else { return }
                
                let (imgData, _) = try await URLSession.shared.data(from: highResUrl)
                await MainActor.run { [weak self] in
                    if let image = NSImage(data: imgData) {
                        self?.artworkCache[cacheKey] = image
                        if self?.currentTrack.title == track.title {
                            self?.artworkImage = image
                        }
                    }
                }
            } catch {
                // Silently fallback if offline
            }
        }
    }
    
    // MARK: - Playback Controls
    public func playPause() {
        executeCommand("playpause")
    }
    
    public func nextTrack() {
        executeCommand("next track")
    }
    
    public func previousTrack() {
        executeCommand("previous track")
    }
    
    private func executeCommand(_ cmd: String) {
        Task.detached(priority: .userInitiated) {
            let scriptText = """
            if application "Music" is running then
                tell application "Music" to \(cmd)
            else if application "Spotify" is running then
                tell application "Spotify" to \(cmd)
            end if
            """
            var err: NSDictionary?
            NSAppleScript(source: scriptText)?.executeAndReturnError(&err)
            
            // Immediate refresh
            try? await Task.sleep(nanoseconds: 200_000_000)
            await MainActor.run { [weak self] in
                self?.refreshNowPlaying()
            }
        }
    }
    
    // MARK: - Quick Actions
    public func quitAllApps() {
        Task.detached(priority: .userInitiated) {
            let runningApps = NSWorkspace.shared.runningApplications
            for app in runningApps {
                guard app.activationPolicy == .regular,
                      app.bundleIdentifier != Bundle.main.bundleIdentifier,
                      app.bundleIdentifier != "com.apple.finder" else {
                    continue
                }
                app.terminate()
            }
        }
    }
    
    public func openTerminal() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
    }
    
    public func openCamera() {
        let photoBoothURL = URL(fileURLWithPath: "/System/Applications/Photo Booth.app")
        if FileManager.default.fileExists(atPath: photoBoothURL.path) {
            NSWorkspace.shared.open(photoBoothURL)
        } else if let ftURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.FaceTime") {
            NSWorkspace.shared.open(ftURL)
        }
    }
    
    public func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }
    
    public func lockScreen() {
        let script = "tell application \"System Events\" to sleep"
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
    }
}
