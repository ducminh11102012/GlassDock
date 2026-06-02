import AppKit

/// Transparent Dock backing.
///
/// The product goal is to keep the row of Dock icons while removing the
/// visible Dock plate entirely. This view intentionally draws nothing: the
/// NSPanel itself is also clear and shadowless, so the desktop wallpaper shows
/// through 100% behind the icons.
final class DockBackgroundView: NSView {
    override var isOpaque: Bool { false }
    override var wantsUpdateLayer: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        // Do not draw any fill, border, gloss, blur, or material. A clear draw
        // avoids the dark rounded rectangle that made the Dock look opaque.
        NSColor.clear.setFill()
        dirtyRect.fill()
    }

    override func updateLayer() {}
}
