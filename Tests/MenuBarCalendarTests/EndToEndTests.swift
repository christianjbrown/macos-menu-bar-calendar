import AppKit

/// Launches the real app binary and quits it the way macOS does, so the entry point
/// runs too. The coverage script sets MBC_APP_BINARY. A plain test run skips this.
@MainActor
func endToEndTests() {
    let t = TestRun.shared
    guard let binary = ProcessInfo.processInfo.environment["MBC_APP_BINARY"] else {
        print("Skipping end-to-end launch: MBC_APP_BINARY is not set")
        return
    }
    t.run("EndToEnd", "launches into the menu bar and quits cleanly") {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        // Pretend the login default already ran, so the test never adds a login item.
        process.arguments = ["-LaunchAtLoginDefaultApplied", "YES"]
        try process.run()

        var app: NSRunningApplication?
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            app = NSRunningApplication(processIdentifier: process.processIdentifier)
            if app?.isFinishedLaunching == true { break }
            spinRunLoop(0.1)
        }
        try expect(app?.isFinishedLaunching == true, "app finished launching")
        spinRunLoop(0.5)
        try expect(app!.terminate(), "quit request was sent")
        while process.isRunning && Date() < deadline.addingTimeInterval(5) {
            spinRunLoop(0.1)
        }
        try expect(!process.isRunning, "app quit")
        try expectEqual(process.terminationStatus, 0)
    }
}
