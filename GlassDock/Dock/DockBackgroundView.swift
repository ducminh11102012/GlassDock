import AppKit

final class DockBackgroundView: NSView {
    var cornerRadius: CGFloat = 20
    var backgroundColor = NSColor(white: 0.15, alpha: 0.72)
    var topGlossOpacity: CGFloat = 0.20
    var borderOpacity: CGFloat = 0.38

    override var isOpaque: Bool { false }
    override var wantsUpdateLayer: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds
        let radius = cornerRadius

        let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        backgroundColor.setFill()
        backgroundPath.fill()

        context.saveGState()
        let glossRect = NSRect(x: rect.minX + 1, y: rect.midY, width: rect.width - 2, height: rect.height / 2)
        let glossPath = NSBezierPath(roundedRect: glossRect, xRadius: max(radius - 1, 0), yRadius: max(radius - 1, 0))
        glossPath.setClip()
        NSGradient(colors: [
            NSColor(white: 1.0, alpha: topGlossOpacity),
            NSColor(white: 1.0, alpha: 0.0)
        ])?.draw(in: glossRect, angle: 90)
        context.restoreGState()

        context.saveGState()
        let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        borderPath.lineWidth = 1.0

        NSColor(white: 1.0, alpha: borderOpacity).setStroke()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2)).setClip()
        borderPath.stroke()
        context.restoreGState()

        context.saveGState()
        NSColor(white: 1.0, alpha: borderOpacity * 0.35).setStroke()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height / 2)).setClip()
        borderPath.stroke()
        context.restoreGState()
    }

    override func updateLayer() {}
}
