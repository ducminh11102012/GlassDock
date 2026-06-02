import AppKit

enum IconFetcher {
    static func icon(bundleID: String?, path: URL?, type: DockItem.ItemType) -> NSImage? {
        if let bundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return normalizedIcon(forFile: appURL.path)
        }

        if let filePath = path?.path, FileManager.default.fileExists(atPath: filePath) {
            return normalizedIcon(forFile: filePath)
        }

        switch type {
        case .folder:
            let folderType = NSFileTypeForHFSTypeCode(OSType(kGenericFolderIcon))
            let icon = NSWorkspace.shared.icon(forFileType: folderType)
            icon.size = NSSize(width: 128, height: 128)
            return icon
        case .trash:
            return NSImage(named: NSImage.trashEmptyName)
        case .app, .file, .separator:
            return NSImage(systemSymbolName: "questionmark.app", accessibilityDescription: "Unknown item")
        }
    }

    private static func normalizedIcon(forFile path: String) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 128, height: 128)
        return icon
    }
}
