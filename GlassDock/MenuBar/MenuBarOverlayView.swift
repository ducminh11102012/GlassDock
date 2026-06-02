import AppKit

final class MenuBarOverlayView: NSView {
    private var wallpaperSlice: NSImage?
    private var activeApplicationName = "Finder"
    private var clockText = ""

    private let horizontalPadding: CGFloat = 14
    private let itemSpacing: CGFloat = 18

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
        refreshDynamicContent()
    }

    func refreshDynamicContent() {
        activeApplicationName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Finder"
        clockText = Self.clockFormatter.string(from: Date())
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        drawTransparentMenuBarBackground()
        drawLeftMenuItems()
        drawRightStatusItems()
    }

    private func drawTransparentMenuBarBackground() {
        if let wallpaperSlice {
            wallpaperSlice.draw(in: bounds)
        } else {
            NSColor.clear.setFill()
            bounds.fill()
        }
    }

    private func drawLeftMenuItems() {
        var x = horizontalPadding
        let baselineY = textY(for: 13)

        drawText("", at: NSPoint(x: x, y: textY(for: 16)), attributes: appleAttributes)
        x += 30

        drawText(activeApplicationName, at: NSPoint(x: x, y: baselineY), attributes: activeAppAttributes)
        x += width(of: activeApplicationName, attributes: activeAppAttributes) + itemSpacing

        for item in localizedMenuItems {
            drawText(item, at: NSPoint(x: x, y: baselineY), attributes: menuItemAttributes)
            x += width(of: item, attributes: menuItemAttributes) + itemSpacing
        }
    }

    private func drawRightStatusItems() {
        var x = bounds.maxX - horizontalPadding
        let baselineY = textY(for: 13)

        x -= width(of: clockText, attributes: menuItemAttributes)
        drawText(clockText, at: NSPoint(x: x, y: baselineY), attributes: menuItemAttributes)
        x -= 18

        for symbolName in ["controlcenter", "magnifyingglass", "keyboard"] {
            let symbolSize = NSSize(width: 14, height: 14)
            x -= symbolSize.width
            drawSymbol(named: symbolName, in: NSRect(x: x, y: (bounds.height - symbolSize.height) / 2, width: symbolSize.width, height: symbolSize.height))
            x -= 14
        }
    }

    private func drawSymbol(named name: String, in rect: NSRect) {
        guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }
        image.isTemplate = true
        NSGraphicsContext.saveGraphicsState()
        menuTextColor.set()
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawText(_ text: String, at point: NSPoint, attributes: [NSAttributedString.Key: Any]) {
        NSString(string: text).draw(at: point, withAttributes: attributes)
    }

    private func width(of text: String, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        NSString(string: text).size(withAttributes: attributes).width
    }

    private func textY(for fontSize: CGFloat) -> CGFloat {
        floor((bounds.height - fontSize) / 2) - 1
    }

    private var localizedMenuItems: [String] {
        if Locale.autoupdatingCurrent.language.languageCode?.identifier == "vi" {
            return ["Tệp", "Sửa", "Xem", "Đi", "Cửa sổ", "Trợ giúp"]
        }
        return ["File", "Edit", "View", "Go", "Window", "Help"]
    }

    private var menuTextColor: NSColor {
        // Keep text Apple-like and readable over most wallpapers. We avoid a
        // background tint because the user requested a fully transparent bar.
        NSColor.black.withAlphaComponent(0.88)
    }

    private var appleAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: menuTextColor
        ]
    }

    private var activeAppAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: menuTextColor
        ]
    }

    private var menuItemAttributes: [NSAttributedString.Key: Any] {
        [
            .font: NSFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: menuTextColor
        ]
    }

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("HH:mm E d MMM")
        return formatter
    }()
}
