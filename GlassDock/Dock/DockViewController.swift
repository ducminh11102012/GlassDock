import AppKit

final class DockViewController: NSViewController {
    private let initialItems: [DockItem]

    init(items: [DockItem]) {
        initialItems = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = DockView(items: initialItems)
    }

    var dockView: DockView? {
        view as? DockView
    }
}
