import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var dockWindow: DockWindow?
    private var menuBarOverlay: MenuBarOverlayWindow?
    private var dockWatcher: DockWatcher?
    private var runningMonitor: RunningAppsMonitor?
    private let dockReader = DockReader()

    func applicationDidFinishLaunching(_ notification: Notification) {
        SystemDockManager.hideSystemDock()
        setupDock()
        setupMenuBarOverlay()
        startWatching()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockWatcher?.stop()
        runningMonitor?.stop()
        NotificationCenter.default.removeObserver(self)
        SystemDockManager.restoreSystemDock()
    }

    private func setupDock() {
        let items = dockReader.readItems()
        dockWindow = DockWindow(items: items)
        dockWindow?.show()
    }

    private func setupMenuBarOverlay() {
        menuBarOverlay = MenuBarOverlayWindow()
        menuBarOverlay?.show()
    }

    private func startWatching() {
        dockWatcher = DockWatcher { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let self else { return }
                self.dockWindow?.updateItems(self.dockReader.readItems())
            }
        }
        dockWatcher?.start()

        runningMonitor = RunningAppsMonitor { [weak self] runningBundleIDs in
            self?.dockWindow?.updateRunningState(runningBundleIDs)
        }
        runningMonitor?.start()
    }

    @objc private func screenDidChange() {
        dockWindow?.reposition()
        menuBarOverlay?.reposition()
        menuBarOverlay?.refreshWallpaper()
    }
}
