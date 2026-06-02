import AppKit

final class MenuBarOverlayView: NSView {
    private var wallpaperSlice: NSImage?

    override var isOpaque: Bool { false }

    func refresh(screen: NSScreen, windowFrame: NSRect) {
        guard let wallpaper = WallpaperReader.wallpaper(for: screen) else {
            wallpaperSlice = nil
            needsDisplay = true
            return
        }

        let menuBarRect = NSRect(
            x: windowFrame.minX - screen.frame.minX,
            y: windowFrame.minY - screen.frame.minY,
            width: windowFrame.width,
            height: windowFrame.height
        )
        wallpaperSlice = WallpaperReader.cropWallpaper(wallpaper, screenSize: screen.frame.size, cropRect: menuBarRect)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        if let wallpaperSlice {
            wallpaperSlice.draw(in: bounds)
        } else {
            NSColor.clear.setFill()
            NSBezierPath(rect: bounds).fill()
        }
    }
}
