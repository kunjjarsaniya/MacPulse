import AppKit
import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Shelf Item Model
public struct ShelfItem: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let fileName: String
    public let fileSizeString: String
    public let icon: NSImage
    public let dateAdded: Date
    
    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.fileName = url.lastPathComponent
        self.dateAdded = Date()
        
        // Format file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useAll]
            formatter.countStyle = .file
            self.fileSizeString = formatter.string(fromByteCount: size)
        } else {
            self.fileSizeString = "--"
        }
        
        // Extract native system icon
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }
    
    public static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shelf Staging Manager
@MainActor
public final class ShelfManager: ObservableObject {
    public static let shared = ShelfManager()
    
    @Published public private(set) var items: [ShelfItem] = []
    @Published public var isTargeted: Bool = false
    
    private init() {}
    
    public func addURL(_ url: URL) {
        // Prevent duplicate URLs in tray
        if !items.contains(where: { $0.url.path == url.path }) {
            let item = ShelfItem(url: url)
            items.insert(item, at: 0)
        }
    }
    
    public func loadProviders(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        if let directURL = item as? URL {
                            Task { @MainActor in
                                self?.addURL(directURL)
                            }
                        }
                        return
                    }
                    Task { @MainActor in
                        self?.addURL(url)
                    }
                }
            }
        }
    }
    
    public func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        items.removeAll()
    }
    
    public func makeItemProvider(for item: ShelfItem) -> NSItemProvider {
        guard let provider = NSItemProvider(contentsOf: item.url) else {
            return NSItemProvider()
        }
        provider.suggestedName = item.fileName
        return provider
    }
}
