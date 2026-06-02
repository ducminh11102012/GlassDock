import AppKit

enum WallpaperReader {
    static func wallpaper(for screen: NSScreen) -> NSImage? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return nil }
        return NSImage(contentsOf: url)
    }

    /// Crops a screen-coordinate rectangle (origin at bottom-left) from a wallpaper image.
    static func cropWallpaper(_ image: NSImage, screenSize: CGSize, cropRect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let scaleX = CGFloat(cgImage.width) / max(screenSize.width, 1)
        let scaleY = CGFloat(cgImage.height) / max(screenSize.height, 1)
        let imageY = screenSize.height - cropRect.maxY
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * scaleX,
            y: imageY * scaleY,
            width: cropRect.width * scaleX,
            height: cropRect.height * scaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard !scaledCropRect.isNull,
              let cropped = cgImage.cropping(to: scaledCropRect) else { return nil }
        return NSImage(cgImage: cropped, size: cropRect.size)
    }
}
