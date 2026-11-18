import AppKit

/// Tells the user something went wrong.
@MainActor
public protocol ErrorPresenting: AnyObject {
    func present(_ error: Error)
}

/// Shows an error in a modal alert with a fixed headline.
@MainActor
public final class AlertErrorPresenter: ErrorPresenting {
    private let title: String

    public init(title: String) {
        self.title = title
    }

    public func present(_ error: Error) {
        _ = makeAlert(for: error).runModal()
    }

    func makeAlert(for error: Error) -> NSAlert {
        let alert = NSAlert(error: error)
        alert.messageText = title
        return alert
    }
}
