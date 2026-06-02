import AppKit

final class MenuBarOverlayWindow: NSPanel {
    private let overlayView = MenuBarOverlayView(frame: .zero)
    private var refreshTimer: Timer?

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure()
        buildUI()
        reposition()
        refreshWallpaper()
        startDynamicRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true

        // Public APIs cannot remove only the system menu-bar background while
        // keeping Apple's private text/icons. Instead, this replacement panel
        // sits above the real menu bar, draws the wallpaper slice, and redraws
        // Apple-like labels/icons. Mouse events still pass through to the real
        // menu bar underneath.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)

        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
    }

    private func buildUI() {
        contentView = overlayView
    }

    func show() {
        orderFrontRegardless()
    }

    func reposition() {
        guard let screen = NSScreen.main else { return }
        let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
        let overlayFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - menuBarHeight,
            width: screen.frame.width,
            height: menuBarHeight
        )
        setFrame(overlayFrame, display: true)
        overlayView.frame = contentView?.bounds ?? .zero
        overlayView.refreshDynamicContent()
    }

    func refreshWallpaper() {
        guard let screen = NSScreen.main else { return }
        overlayView.refresh(screen: screen, windowFrame: frame)
    }

    private func startDynamicRefresh() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.overlayView.refreshDynamicContent()
        }
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
