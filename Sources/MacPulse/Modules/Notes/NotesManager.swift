import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Notes Manager
@MainActor
public final class NotesManager: ObservableObject {
    public static let shared = NotesManager()
    
    private let storageKey = "com.macpulse.quickNotes"
    
    @Published public var noteText: String {
        didSet {
            UserDefaults.standard.set(noteText, forKey: storageKey)
        }
    }
    
    private init() {
        self.noteText = UserDefaults.standard.string(forKey: storageKey) ?? ""
    }
    
    public var characterCount: Int {
        noteText.count
    }
    
    public var wordCount: Int {
        noteText.split { $0.isWhitespace || $0.isNewline }.count
    }
    
    public func copyAll() {
        guard !noteText.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(noteText, forType: .string)
    }
    
    public func clear() {
        noteText = ""
    }
}
