import AppKit
import Foundation

struct DockItem: Identifiable, Equatable {
    let id = UUID()
    var bundleIdentifier: String?
    var path: URL?
    var name: String
    var icon: NSImage?
    var isRunning: Bool = false
    var itemType: ItemType

    enum ItemType: Equatable {
        case app
        case folder
        case file
        case trash
        case separator
    }

    var isSeparator: Bool { itemType == .separator }

    static func == (lhs: DockItem, rhs: DockItem) -> Bool {
        lhs.id == rhs.id
    }
}
