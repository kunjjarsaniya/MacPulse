import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Clipboard Entry Model
public struct ClipboardEntry: Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let date: Date
    
    public init(content: String) {
        self.id = UUID()
        self.content = content
        self.date = Date()
    }
}

// MARK: - Clipboard Manager
@MainActor
public final class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()
    
    @Published public private(set) var history: [ClipboardEntry] = []
    @Published public var searchText: String = ""
    
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    private init() {
        lastChangeCount = NSPasteboard.general.changeCount
        loadInitial()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func loadInitial() {
        if let currentString = NSPasteboard.general.string(forType: .string),
           !currentString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            history.append(ClipboardEntry(content: currentString))
        }
    }
    
    public func startMonitoring() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard()
            }
        }
    }
    
    private func checkPasteboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        guard let string = NSPasteboard.general.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Avoid duplicate consecutive entries
        if let first = history.first, first.content == string {
            return
        }
        
        // Prepend new entry
        history.insert(ClipboardEntry(content: string), at: 0)
        
        // Cap at 50 items
        if history.count > 50 {
            history.removeLast()
        }
    }
    
    public func copyEntry(_ entry: ClipboardEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    public func deleteEntry(id: UUID) {
        history.removeAll { $0.id == id }
    }
    
    public func clearHistory() {
        history.removeAll()
    }
    
    public var filteredHistory: [ClipboardEntry] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return history
        }
        return history.filter {
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
}
