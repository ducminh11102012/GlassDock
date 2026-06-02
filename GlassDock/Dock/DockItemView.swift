import AppKit

final class DockItemView: NSView {
    private(set) var item: DockItem
    var onTap: (() -> Void)?
    var onRightClick: ((NSEvent) -> Void)?

    private let hoverHighlightView = NSView(frame: .zero)
    private let iconImageView = NSImageView(frame: .zero)
    private let dotView = NSView(frame: .zero)
    private var tooltipWindow: NSPanel?
    private var bounceTimer: Timer?
    private var currentScale: CGFloat = 1.0
    private var baseFrameOrigin: NSPoint = .zero

    private static let baseIconSize: CGFloat = 52
    private static let scaleByDistance: [Int: CGFloat] = [0: 1.38, 1: 1.20, 2: 1.10]

    init(item: DockItem) {
        self.item = item
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        wantsLayer = true
        layer?.masksToBounds = false

        hoverHighlightView.wantsLayer = true
        hoverHighlightView.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.18).cgColor
        hoverHighlightView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.28).cgColor
        hoverHighlightView.layer?.borderWidth = 0.75
        hoverHighlightView.layer?.cornerRadius = 13
        hoverHighlightView.alphaValue = 0
        addSubview(hoverHighlightView)

        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.image = item.icon
        iconImageView.wantsLayer = true
        iconImageView.layer?.cornerRadius = Self.baseIconSize * 0.22
        iconImageView.layer?.masksToBounds = true
        addSubview(iconImageView)

        dotView.wantsLayer = true
        dotView.layer?.backgroundColor = NSColor(white: 0.9, alpha: 0.85).cgColor
        dotView.layer?.cornerRadius = 2
        dotView.isHidden = !item.isRunning
        addSubview(dotView)
    }

    override func layout() {
        super.layout()
        let iconSize = Self.baseIconSize * currentScale
        let dotSize: CGFloat = 4
        let iconX = (bounds.width - iconSize) / 2
        let dotY: CGFloat = 2
        let iconY = dotY + dotSize + 2

        iconImageView.frame = NSRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
        hoverHighlightView.frame = iconImageView.frame.insetBy(dx: -4, dy: -4)
        dotView.frame = NSRect(x: (bounds.width - dotSize) / 2, y: dotY, width: dotSize, height: dotSize)
    }

    func setMagnification(distance: Int, isHovered: Bool) {
        hoverHighlightView.animator().alphaValue = isHovered ? 1 : 0

        let scale = Self.scaleByDistance[distance] ?? 1.0
        guard scale != currentScale else { return }
        if currentScale == 1.0 {
            baseFrameOrigin = frame.origin
        }
        currentScale = scale
        let liftY = (scale - 1.0) * Self.baseIconSize * 0.5

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrameOrigin(NSPoint(x: baseFrameOrigin.x, y: baseFrameOrigin.y + liftY))
        }
        needsLayout = true
    }

    func updateItem(_ item: DockItem) {
        self.item = item
        iconImageView.image = item.icon
        updateRunningState(item.isRunning)
    }

    func updateRunningState(_ running: Bool) {
        item.isRunning = running
        dotView.isHidden = !running
    }

    override func mouseEntered(with event: NSEvent) {
        (superview as? DockView)?.notifyHover(self)
        showTooltip()
    }

    override func mouseExited(with event: NSEvent) {
        (superview as? DockView)?.notifyHover(nil)
        hideTooltip()
    }

    override func mouseUp(with event: NSEvent) {
        guard event.clickCount == 1 else { return }
        bounceThenLaunch()
    }

    override func rightMouseUp(with event: NSEvent) {
        onRightClick?(event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    private func bounceThenLaunch() {
        onTap?()
        guard item.itemType == .app else { return }
        bounceTimer?.invalidate()

        var count = 0
        bounceTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            let offset: CGFloat = count.isMultiple(of: 2) ? 16 : -16
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                self.animator().setFrameOrigin(NSPoint(x: self.frame.origin.x, y: self.frame.origin.y + offset))
            }
            count += 1
            if count >= 4 {
                timer.invalidate()
                self.bounceTimer = nil
            }
        }
    }

    private func showTooltip() {
        guard !item.name.isEmpty, !item.isSeparator, tooltipWindow == nil else { return }

        let label = NSTextField(labelWithString: item.name)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.sizeToFit()

        let padding: CGFloat = 10
        let tooltipWidth = label.frame.width + padding * 2
        let tooltipHeight: CGFloat = 24
        label.frame = NSRect(x: padding, y: (tooltipHeight - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: tooltipWidth, height: tooltipHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(white: 0.10, alpha: 0.88).cgColor
        contentView.layer?.cornerRadius = 7
        contentView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.18).cgColor
        contentView.layer?.borderWidth = 0.5
        contentView.addSubview(label)

        let window = NSPanel(contentRect: contentView.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 2)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.contentView = contentView

        let pointInWindow = convert(NSPoint(x: bounds.midX, y: bounds.maxY + 12), to: nil)
        if let screenPoint = self.window?.convertPoint(toScreen: pointInWindow) {
            window.setFrameOrigin(NSPoint(x: screenPoint.x - tooltipWidth / 2, y: screenPoint.y))
        }

        tooltipWindow = window
        window.orderFront(nil)
    }

    private func hideTooltip() {
        tooltipWindow?.orderOut(nil)
        tooltipWindow = nil
    }
}
