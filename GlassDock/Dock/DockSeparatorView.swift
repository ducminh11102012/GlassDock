import AppKit

final class DockSeparatorView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 1.0, alpha: 0.22).setFill()
        let rect = NSRect(x: 0, y: (bounds.height - 44) / 2, width: 1, height: 44)
        NSBezierPath(rect: rect).fill()
    }
}
