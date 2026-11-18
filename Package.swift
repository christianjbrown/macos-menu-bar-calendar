// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MenuBarCalendar",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure date and layout logic. Foundation only, no AppKit.
        .target(name: "CalendarCore"),
        // AppKit views, controllers and the adapters around system services.
        .target(name: "MenuBarCalendarKit", dependencies: ["CalendarCore"]),
        // The app entry point: wires the composition root into NSApplication.
        .executableTarget(name: "MenuBarCalendar", dependencies: ["MenuBarCalendarKit"]),
        // XCTest and Swift Testing do not build with the Command Line Tools alone,
        // so the unit tests are a plain executable: `swift run MenuBarCalendarTests`.
        .executableTarget(
            name: "MenuBarCalendarTests",
            dependencies: ["CalendarCore", "MenuBarCalendarKit"],
            path: "Tests/MenuBarCalendarTests"
        ),
    ]
)
