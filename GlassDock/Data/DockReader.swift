import AppKit
import Foundation

final class DockReader {
    private let finderBundleIdentifier = "com.apple.finder"
    private let finderPath = "/System/Library/CoreServices/Finder.app"
    private let plistURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Preferences/com.apple.dock.plist")

    func readItems() -> [DockItem] {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)

        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return fallbackItems()
        }

        var appItems: [DockItem] = []
        if let apps = plist["persistent-apps"] as? [[String: Any]] {
            appItems = apps.compactMap { parseTile($0, defaultType: .app) }
        }

        // Finder is a permanent Apple Dock item and is usually not stored in
        // persistent-apps, so inject it to keep GlassDock visually in sync with
        // the real Dock instead of starting at Launchpad/Safari.
        var items = ensureFinderIsFirst(in: appItems)

        items.append(DockItem(name: "", icon: nil, itemType: .separator))

        if let others = plist["persistent-others"] as? [[String: Any]] {
            items += others.compactMap { parseTile($0, defaultType: .folder) }
        }

        let trashFull = plist["trash-full"] as? Bool ?? false
        let trashIcon = NSImage(named: trashFull ? NSImage.trashFullName : NSImage.trashEmptyName)
        items.append(DockItem(name: "Trash", icon: trashIcon, itemType: .trash))

        return items
    }

    private func ensureFinderIsFirst(in appItems: [DockItem]) -> [DockItem] {
        var filteredItems = appItems.filter { $0.bundleIdentifier != finderBundleIdentifier }
        filteredItems.insert(finderItem(), at: 0)
        return filteredItems
    }

    private func finderItem() -> DockItem {
        let finderURL = URL(fileURLWithPath: finderPath)
        let finderIcon = NSWorkspace.shared.icon(forFile: finderURL.path)
        finderIcon.size = NSSize(width: 128, height: 128)
        return DockItem(
            bundleIdentifier: finderBundleIdentifier,
            path: finderURL,
            name: "Finder",
            icon: finderIcon,
            isRunning: true,
            itemType: .app
        )
    }

    private func parseTile(_ dict: [String: Any], defaultType: DockItem.ItemType) -> DockItem? {
        guard let tileData = dict["tile-data"] as? [String: Any] else { return nil }

        let label = tileData["file-label"] as? String ?? "Unknown"
        let bundleID = tileData["bundle-identifier"] as? String
        let path = parseFileURL(from: tileData["file-data"] as? [String: Any])
        let type = itemType(from: dict["tile-type"] as? String, defaultType: defaultType)
        let icon = IconFetcher.icon(bundleID: bundleID, path: path, type: type)

        return DockItem(bundleIdentifier: bundleID, path: path, name: label, icon: icon, itemType: type)
    }

    private func parseFileURL(from fileData: [String: Any]?) -> URL? {
        guard let fileData else { return nil }
        if let urlString = fileData["_CFURLString"] as? String {
            if let base = fileData["_CFURLStringType"] as? Int, base == 0 {
                return URL(fileURLWithPath: urlString)
            }
            return URL(string: urlString)
        }
        return nil
    }

    private func itemType(from tileType: String?, defaultType: DockItem.ItemType) -> DockItem.ItemType {
        switch tileType {
        case "directory-tile": return .folder
        case "file-tile": return .file
        default: return defaultType
        }
    }

    private func fallbackItems() -> [DockItem] {
        return [
            finderItem(),
            DockItem(name: "", icon: nil, itemType: .separator),
            DockItem(name: "Trash", icon: NSImage(named: NSImage.trashEmptyName), itemType: .trash)
        ]
    }
}
