import AppKit
import ServiceManagement

// Seams around system services. Each protocol is the small slice of an AppKit or
// ServiceManagement type that the app needs, so the controllers can be given fakes.
// The system types already have these members, so the conformances add no code.

@MainActor
public protocol StatusBarProviding: AnyObject {
    func statusItem(withLength length: CGFloat) -> NSStatusItem
    func removeStatusItem(_ item: NSStatusItem)
}

@MainActor
public protocol LoginItemService: AnyObject {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

/// Remembers small settings between launches.
public protocol SettingsStore: AnyObject {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

@MainActor
public protocol EventSource: AnyObject {
    var currentEvent: NSEvent? { get }
}

@MainActor
public protocol AppActivating: AnyObject {
    func activate(ignoringOtherApps flag: Bool)
}

@MainActor
public protocol ApplicationRunning: AnyObject {
    var delegate: NSApplicationDelegate? { get set }
    func setActivationPolicy(_ activationPolicy: NSApplication.ActivationPolicy) -> Bool
    func run()
}

extension NSStatusBar: StatusBarProviding {}
extension SMAppService: LoginItemService {}
extension UserDefaults: SettingsStore {}
extension NSApplication: EventSource, AppActivating, ApplicationRunning {}
