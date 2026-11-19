import Foundation

/// Asks once, on the first launch, whether to open the app at login.
///
/// Nothing is registered unless the user says yes. The answer is recorded either way, so
/// the question never comes back; the status item's menu changes it later.
@MainActor
public final class LaunchAtLoginPrompt {
    /// The stored name predates the question, when the app switched itself on. Keeping it
    /// means people who already have the app installed are not asked again.
    static let askedKey = "LaunchAtLoginDefaultApplied"

    private let loginItem: LoginItemService
    private let settings: SettingsStore
    private let question: LaunchAtLoginAsking
    private let errorPresenter: ErrorPresenting

    public init(loginItem: LoginItemService, settings: SettingsStore, question: LaunchAtLoginAsking,
                errorPresenter: ErrorPresenting) {
        self.loginItem = loginItem
        self.settings = settings
        self.question = question
        self.errorPresenter = errorPresenter
    }

    public func apply() {
        guard !settings.bool(forKey: Self.askedKey) else { return }
        let wantsLaunchAtLogin = question.askToLaunchAtLogin()
        settings.set(true, forKey: Self.askedKey)
        guard wantsLaunchAtLogin else { return }
        do {
            try loginItem.register()
        } catch {
            errorPresenter.present(error)
        }
    }
}
