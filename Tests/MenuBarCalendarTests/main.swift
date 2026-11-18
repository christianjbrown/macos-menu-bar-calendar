import AppKit

MainActor.assumeIsolated {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.accessory)

    coreTests()
    localisationTests()
    kitTests()
    appTests()
    endToEndTests()

    let run = TestRun.shared
    for failure in run.failures {
        print("FAIL \(failure)")
    }
    print("\(run.passed) passed, \(run.failures.count) failed")
    exit(run.failures.isEmpty ? 0 : 1)
}
