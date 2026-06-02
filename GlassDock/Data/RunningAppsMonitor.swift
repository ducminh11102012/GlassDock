import AppKit

final class RunningAppsMonitor {
    private let callback: (Set<String>) -> Void
    private var observers: [NSObjectProtocol] = []

    init(onUpdate: @escaping (Set<String>) -> Void) {
        callback = onUpdate
    }

    func start() {
        notify()
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification
        ]
        observers = names.map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.notify()
            }
        }
    }

    func stop() {
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
    }

    private func notify() {
        let ids = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        callback(ids)
    }
}
