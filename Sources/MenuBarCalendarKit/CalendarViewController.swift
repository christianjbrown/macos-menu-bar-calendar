import AppKit
import CalendarCore

/// Accepts a nudge to re-read today's date, after midnight or a clock change.
@MainActor
public protocol TodayRefreshing: AnyObject {
    func refreshToday()
}

/// Closes whatever is showing the calendar.
@MainActor
protocol CalendarDismissing: AnyObject {
    func close()
}

/// The popover content: a clickable title and navigation buttons above the grid.
/// It owns the calendar state and turns user input into state changes.
public final class CalendarViewController: NSViewController, CalendarGridViewDelegate, TodayRefreshing {
    let grid = CalendarGridView()
    /// The title pieces: month name and year, just the year, or a range of years.
    let titleButtons = [makeTitleButton(tag: 0), makeTitleButton(tag: 1)]
    let previousButton: NSButton
    let nextButton: NSButton
    weak var dismisser: CalendarDismissing?

    private let clock: Clock
    private let calendar: Calendar
    private(set) var state: CalendarState
    private var titleParts: [HeaderPart] = []

    public init(clock: Clock, calendar: Calendar, strings: AppStrings) {
        self.clock = clock
        self.calendar = calendar
        previousButton = Self.makeButton(symbol: "chevron.left", label: strings.previous, pointSize: 11)
        nextButton = Self.makeButton(symbol: "chevron.right", label: strings.next, pointSize: 11)
        state = CalendarState(today: Day(clock.now(), calendar: calendar))
        super.init(nibName: nil, bundle: nil)
    }

    /// The calendar is built in code, never from a nib.
    required init?(coder: NSCoder) {
        return nil
    }

    public override func loadView() {
        for button in titleButtons {
            button.target = self
            button.action = #selector(titleClicked(_:))
        }
        previousButton.target = self
        previousButton.action = #selector(showPrevious)
        nextButton.target = self
        nextButton.action = #selector(showNext)
        grid.delegate = self

        let title = NSStackView(views: titleButtons)
        title.spacing = 4
        let buttons = NSStackView(views: [previousButton, nextButton])
        buttons.spacing = 2
        let header = NSStackView(views: [title, NSView(), buttons])
        let stack = NSStackView(views: [header, grid])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: grid.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])
        view = container
        render()
    }

    /// Starts afresh on today's month, as each time the popover opens.
    func showToday() {
        state = CalendarState(today: Day(clock.now(), calendar: calendar))
        render()
    }

    public func refreshToday() {
        state.updateToday(Day(clock.now(), calendar: calendar))
        render()
    }

    func focusGrid() {
        view.window?.makeFirstResponder(grid)
    }

    // MARK: Actions

    @objc func titleClicked(_ sender: NSButton) {
        if let command = titleParts[sender.tag].command {
            apply(command)
        }
    }

    @objc func showPrevious() {
        apply(.step(-1))
    }

    @objc func showNext() {
        apply(.step(1))
    }

    // MARK: CalendarGridViewDelegate

    func gridView(_ gridView: CalendarGridView, didRequest command: CalendarCommand) {
        apply(command)
    }

    func gridView(_ gridView: CalendarGridView, handle key: Key) -> Bool {
        switch KeyMap.action(for: key) {
        case .command(let command)?:
            apply(command)
            return true
        case .dismiss?:
            dismisser?.close()
            return true
        case nil:
            return false
        }
    }

    func gridView(_ gridView: CalendarGridView, didScroll steps: Int) {
        apply(.step(steps))
    }

    // MARK: Private

    private func apply(_ command: CalendarCommand) {
        state.apply(command, calendar: calendar)
        render()
    }

    private func render() {
        grid.page = CalendarPage(state: state, calendar: calendar)
        titleParts = CalendarHeader.parts(for: state, calendar: calendar)
        for (index, button) in titleButtons.enumerated() {
            button.isHidden = index >= titleParts.count
            button.attributedTitle = NSAttributedString(
                string: button.isHidden ? "" : titleParts[index].text,
                attributes: [.font: Palette.titleFont, .foregroundColor: NSColor.labelColor])
        }
    }

    private static func makeTitleButton(tag: Int) -> NSButton {
        let button = NSButton(title: "", target: nil, action: nil)
        button.isBordered = false
        button.tag = tag
        return button
    }

    private static func makeButton(symbol: String, label: String, pointSize: CGFloat) -> NSButton {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)!
            .withSymbolConfiguration(configuration)!
        let button = NSButton(image: image, target: nil, action: nil)
        button.isBordered = false
        button.contentTintColor = .secondaryLabelColor
        button.toolTip = label
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 20),
            button.heightAnchor.constraint(equalToConstant: 20),
        ])
        return button
    }
}
