import Darwin
import Foundation

final class DockWatcher {
    private let callback: () -> Void
    private var kqueueDescriptor: Int32 = -1
    private var watchedDescriptor: Int32 = -1
    private var thread: Thread?
    private var isRunning = false

    private let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist"

    init(onChange: @escaping () -> Void) {
        callback = onChange
    }

    deinit {
        stop()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        thread = Thread { [weak self] in self?.watchLoop() }
        thread?.name = "GlassDock.PlistWatcher"
        thread?.start()
    }

    func stop() {
        isRunning = false
        if kqueueDescriptor != -1 {
            close(kqueueDescriptor)
            kqueueDescriptor = -1
        }
        if watchedDescriptor != -1 {
            close(watchedDescriptor)
            watchedDescriptor = -1
        }
    }

    private func watchLoop() {
        while isRunning {
            guard openDescriptors() else {
                Thread.sleep(forTimeInterval: 1.0)
                continue
            }
            watchCurrentFileDescriptor()
            closeWatchedDescriptor()
        }
    }

    private func openDescriptors() -> Bool {
        if kqueueDescriptor == -1 {
            kqueueDescriptor = kqueue()
        }
        guard kqueueDescriptor != -1 else { return false }

        watchedDescriptor = open(plistPath, O_RDONLY | O_EVTONLY)
        return watchedDescriptor != -1
    }

    private func watchCurrentFileDescriptor() {
        // Swift cannot call the C EV_SET macro directly, so initialize kevent manually.
        var event = kevent(
            ident: UInt(watchedDescriptor),
            filter: Int16(EVFILT_VNODE),
            flags: UInt16(EV_ADD | EV_ENABLE | EV_CLEAR),
            fflags: UInt32(NOTE_WRITE | NOTE_RENAME | NOTE_DELETE | NOTE_REVOKE),
            data: 0,
            udata: nil
        )
        kevent(kqueueDescriptor, &event, 1, nil, 0, nil)

        while isRunning {
            var timeout = timespec(tv_sec: 5, tv_nsec: 0)
            var received = kevent()
            let result = kevent(kqueueDescriptor, nil, 0, &received, 1, &timeout)
            if result > 0 {
                DispatchQueue.main.async { [weak self] in self?.callback() }
                if received.fflags & UInt32(NOTE_RENAME | NOTE_DELETE | NOTE_REVOKE) != 0 {
                    break
                }
            }
        }
    }

    private func closeWatchedDescriptor() {
        if watchedDescriptor != -1 {
            close(watchedDescriptor)
            watchedDescriptor = -1
        }
    }
}
