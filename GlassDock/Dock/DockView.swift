import AppKit

final class DockView: NSView {
    private var items: [DockItem] = []
    private var itemViews: [NSView] = []
    private let backgroundView = DockBackgroundView(frame: .zero)

    private let iconSize: CGFloat = 52
    private let iconSpacing: CGFloat = 6
    private let paddingH: CGFloat = 14
    private let paddingV: CGFloat = 10
    private let dotHeight: CGFloat = 6

    private var hoveredView: DockItemView?

    override var intrinsicContentSize: NSSize {
        let icons = items.filter { !$0.isSeparator }.count
        let separators = items.filter(\.isSeparator).count
        let width = paddingH * 2
            + CGFloat(icons) * iconSize
            + CGFloat(max(0, icons - 1)) * iconSpacing
            + CGFloat(separators) * (1 + iconSpacing * 2)
        let height = paddingV * 2 + iconSize + dotHeight
        return NSSize(width: max(width, 100), height: height)
    }

    init(items: [DockItem]) {
        super.init(frame: .zero)
        wantsLayer = false
        setupBackground()
        setItems(items)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBackground() {
        backgroundView.autoresizingMask = [.width, .height]
        addSubview(backgroundView)
    }

    func setItems(_ items: [DockItem]) {
        self.items = items
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        for item in items {
            let view: NSView
            if item.isSeparator {
                view = DockSeparatorView(frame: .zero)
            } else {
                let itemView = DockItemView(item: item)
                itemView.onTap = { AppLauncher.open(item) }
                itemView.onRightClick = { [weak self] event in self?.showContextMenu(for: itemView.item, event: event) }
                view = itemView
            }
            itemViews.append(view)
            addSubview(view)
        }

        needsLayout = true
        invalidateIntrinsicContentSize()
    }

    override func layout() {
        super.layout()
        backgroundView.frame = bounds

        var x = paddingH
        let iconY = paddingV + dotHeight
        for view in itemViews {
            if view is DockSeparatorView {
                view.frame = NSRect(x: x + iconSpacing / 2, y: iconY + (iconSize - 44) / 2, width: 1, height: 44)
                x += 1 + iconSpacing * 2
            } else {
                view.frame = NSRect(x: x, y: iconY - iconSize * 0.1, width: iconSize, height: iconSize + dotHeight)
                x += iconSize + iconSpacing
            }
        }
    }

    func notifyHover(_ view: DockItemView?) {
        hoveredView = view
        for itemView in itemViews.compactMap({ $0 as? DockItemView }) {
            itemView.setMagnification(distance: distanceFromHovered(to: itemView), isHovered: itemView === view)
        }
    }

    private func distanceFromHovered(to view: DockItemView) -> Int {
        guard let hoveredView,
              let hoveredIndex = itemViews.firstIndex(where: { $0 === hoveredView }),
              let viewIndex = itemViews.firstIndex(where: { $0 === view }) else {
            return 99
        }
        return abs(hoveredIndex - viewIndex)
    }

    private func showContextMenu(for item: DockItem, event: NSEvent) {
        let menu = NSMenu()

        if item.isRunning {
            menu.addItem(withTitle: "Ẩn \(item.name)", action: #selector(hideApp(_:)), keyEquivalent: "")
            menu.addItem(withTitle: "Thoát", action: #selector(quitApp(_:)), keyEquivalent: "")
            menu.addItem(.separator())
        }

        menu.addItem(withTitle: "Mở", action: #selector(openApp(_:)), keyEquivalent: "")
        if item.itemType == .app || item.itemType == .folder || item.itemType == .file {
            menu.addItem(withTitle: "Xem trong Finder", action: #selector(revealInFinder(_:)), keyEquivalent: "")
        }

        for menuItem in menu.items where menuItem.action != nil {
            menuItem.representedObject = item
            menuItem.target = self
        }

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func openApp(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockItem else { return }
        AppLauncher.open(item)
    }

    @objc private func hideApp(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockItem else { return }
        AppLauncher.hide(item)
    }

    @objc private func quitApp(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockItem else { return }
        AppLauncher.quit(item)
    }

    @objc private func revealInFinder(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockItem else { return }
        AppLauncher.revealInFinder(item)
    }

    func updateRunningState(_ runningBundleIDs: Set<String>) {
        for itemView in itemViews.compactMap({ $0 as? DockItemView }) {
            guard let bundleID = itemView.item.bundleIdentifier else { continue }
            itemView.updateRunningState(runningBundleIDs.contains(bundleID))
        }
    }
}
