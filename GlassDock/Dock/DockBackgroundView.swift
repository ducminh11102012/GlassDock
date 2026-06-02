import AppKit

/// Apple-like transparent Dock shelf.
///
/// The effect is a very light alpha fill plus simple Core Graphics
/// gradients/borders. This keeps the wallpaper
/// visible through the Dock while avoiding the opaque dark plate from earlier
/// builds.
final class DockBackgroundView: NSView {
    private let cornerRadius: CGFloat = 19
    private let shelfFill = NSColor(white: 1.0, alpha: 0.16)
    private let topGlossOpacity: CGFloat = 0.18
    private let topBorderOpacity: CGFloat = 0.34
    private let bottomBorderOpacity: CGFloat = 0.10

    override var isOpaque: Bool { false }
    override var wantsUpdateLayer: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let shelfPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

        // Soft translucent shelf: enough shape to feel like the Apple Dock,
        // but low alpha so the wallpaper remains visible behind the icons.
        shelfFill.setFill()
        shelfPath.fill()

        context.saveGState()
        shelfPath.setClip()

        let glossRect = NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)
        NSGradient(colors: [
            NSColor(white: 1.0, alpha: topGlossOpacity),
            NSColor(white: 1.0, alpha: 0.02)
        ])?.draw(in: glossRect, angle: 90)

        let shadeRect = NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)
        NSGradient(colors: [
            NSColor(white: 0.0, alpha: 0.06),
            NSColor(white: 0.0, alpha: 0.00)
        ])?.draw(in: shadeRect, angle: 270)
        context.restoreGState()

        context.saveGState()
        let borderPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        borderPath.lineWidth = 1.0

        NSColor(white: 1.0, alpha: topBorderOpacity).setStroke()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)).setClip()
        borderPath.stroke()
        context.restoreGState()

        context.saveGState()
        NSColor(white: 1.0, alpha: bottomBorderOpacity).setStroke()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)).setClip()
        borderPath.stroke()
        context.restoreGState()
    }

    override func updateLayer() {}
}
