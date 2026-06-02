import AppKit

enum AppLauncher {
    static func open(_ item: DockItem) {
        switch item.itemType {
        case .app:
            openApp(item)
        case .folder, .file:
            if let url = item.path { NSWorkspace.shared.open(url) }
        case .trash:
            if let trashURL = URL(string: "trash://") { NSWorkspace.shared.open(trashURL) }
        case .separator:
            break
        }
    }

    static func quit(_ item: DockItem) {
        runningApplication(for: item)?.terminate()
    }

    static func hide(_ item: DockItem) {
        runningApplication(for: item)?.hide()
    }

    static func revealInFinder(_ item: DockItem) {
        guard let url = item.path else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private static func openApp(_ item: DockItem) {
        if let running = runningApplication(for: item) {
            running.activate(options: [.activateAllWindows])
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        if let bundleID = item.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
        } else if let url = item.path {
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        }
    }

    private static func runningApplication(for item: DockItem) -> NSRunningApplication? {
        guard let bundleID = item.bundleIdentifier else { return nil }
        return NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleID }
    }
}
