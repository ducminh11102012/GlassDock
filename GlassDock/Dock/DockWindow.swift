import AppKit

final class DockWindow: NSPanel {
    private let dockViewController: DockViewController
    private var items: [DockItem]

    init(items: [DockItem]) {
        self.items = items
        dockViewController = DockViewController(items: items)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
        buildUI()
        reposition()
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isMovable = false
        ignoresMouseEvents = false
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
    }

    private func buildUI() {
        contentViewController = dockViewController
        setContentSize(dockViewController.view.intrinsicContentSize)
    }

    func show() {
        orderFrontRegardless()
    }

    func reposition() {
        guard let screen = NSScreen.main else { return }
        let width = frame.width
        let x = screen.frame.minX + (screen.frame.width - width) / 2
        let y = screen.frame.minY + 8
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func updateItems(_ items: [DockItem]) {
        self.items = items
        dockViewController.dockView?.setItems(items)
        setContentSize(dockViewController.view.intrinsicContentSize)
        reposition()
    }

    func updateRunningState(_ runningBundleIDs: Set<String>) {
        dockViewController.dockView?.updateRunningState(runningBundleIDs)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
