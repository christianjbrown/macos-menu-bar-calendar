import Foundation

/// Turns Launch at Login on the first time the app runs.
///
/// It only ever does this once, so switching it off in the menu sticks. If registering
/// fails, nothing is recorded and it tries again on the next launch.
@MainActor
public final class LaunchAtLoginDefault {
    static let appliedKey = "LaunchAtLoginDefaultApplied"

    private let loginItem: LoginItemService
    private let settings: SettingsStore

    public init(loginItem: LoginItemService, settings: SettingsStore) {
        self.loginItem = loginItem
        self.settings = settings
    }

    public func apply() {
        guard !settings.bool(forKey: Self.appliedKey) else { return }
        do {
            try loginItem.register()
            settings.set(true, forKey: Self.appliedKey)
        } catch {
            // Leave the flag unset so the next launch tries again.
        }
    }
}
