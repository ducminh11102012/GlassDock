import Foundation

enum SystemDockManager {
    static func hideSystemDock() {
        run("defaults write com.apple.dock autohide -bool true")
        run("defaults write com.apple.dock autohide-delay -float 1000")
        run("killall Dock")
        Thread.sleep(forTimeInterval: 1.5)
    }

    static func restoreSystemDock() {
        run("defaults delete com.apple.dock autohide-delay 2>/dev/null || true")
        run("defaults write com.apple.dock autohide -bool false")
        run("killall Dock")
    }

    @discardableResult
    private static func run(_ command: String) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }
}
