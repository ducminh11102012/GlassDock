import AppKit

final class MenuBarOverlayWindow: NSPanel {
    private let overlayView = MenuBarOverlayView(frame: .zero)

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configure()
        buildUI()
        reposition()
        refreshWallpaper()
    }

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
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
    }

    func refreshWallpaper() {
        guard let screen = NSScreen.main else { return }
        overlayView.refresh(screen: screen, windowFrame: frame)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
