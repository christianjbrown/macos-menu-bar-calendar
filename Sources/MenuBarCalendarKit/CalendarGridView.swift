import AppKit
import CalendarCore

/// Receives what the user does in the grid. The grid itself never changes the calendar state.
@MainActor
protocol CalendarGridViewDelegate: AnyObject {
    func gridView(_ gridView: CalendarGridView, didRequest command: CalendarCommand)
    /// Returns false when the key is not a calendar shortcut, so it can travel up the responder chain.
    func gridView(_ gridView: CalendarGridView, handle key: Key) -> Bool
    func gridView(_ gridView: CalendarGridView, didScroll steps: Int)
}

/// Draws the current page (a month of days, or a month or year picker) and reports
/// clicks, keys and scrolling to its delegate.
final class CalendarGridView: NSView {
    let geometry = GridGeometry.standard
    weak var delegate: CalendarGridViewDelegate?

    var page: CalendarPage? {
        didSet {
            hoveredIndex = nil
            needsDisplay = true
        }
    }

    private(set) var hoveredIndex: Int? {
        didSet {
            if hoveredIndex != oldValue {
                needsDisplay = true
            }
        }
    }

    private var stepper = ScrollStepper()

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { geometry.size }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        switch page {
        case .days(let grid, let today, let selected)?:
            drawDays(grid, today: today, selected: selected)
        case .picker(let picker)?:
            drawPicker(picker)
        case nil:
            break
        }
    }

    private func drawDays(_ grid: MonthGrid, today: Day, selected: Day) {
        let attributes = textAttributes(font: Palette.headerFont, color: Palette.header)
        for (column, symbol) in grid.weekdaySymbols.enumerated() {
            (symbol as NSString).draw(in: geometry.headerRect(column: column), withAttributes: attributes)
        }
        Palette.separator.setFill()
        geometry.separatorRect.fill()

        let hovered = hoveredIndex.map { grid.days[$0] }
        for (index, day) in grid.days.enumerated() {
            let style = CellStyle(day: day, month: grid.month, today: today, selected: selected, hovered: hovered)
            drawCell("\(day.day)", in: geometry.cellRect(index: index).insetBy(dx: 2, dy: 1.5),
                     style: style, fontSize: 12)
        }
    }

    private func drawPicker(_ picker: PickerGrid) {
        for (index, item) in picker.items.enumerated() {
            let style = CellStyle(item: item, isHovered: index == hoveredIndex)
            drawCell(item.label, in: geometry.pickerCellRect(index: index).insetBy(dx: 3, dy: 6),
                     style: style, fontSize: 13)
        }
    }

    private func drawCell(_ label: String, in rect: NSRect, style: CellStyle, fontSize: CGFloat) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        if let fill = Palette.background(style.background) {
            fill.setFill()
            path.fill()
        }
        if style.outlined {
            Palette.outline.setStroke()
            path.lineWidth = 1.25
            path.stroke()
        }

        let attributes = textAttributes(font: Palette.font(style.text, size: fontSize),
                                        color: Palette.textColor(style.text))
        let text = label as NSString
        let height = text.size(withAttributes: attributes).height
        text.draw(in: NSRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height),
                  withAttributes: attributes)
    }

    private func textAttributes(font: NSFont, color: NSColor) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        return [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
    }

    // MARK: Input

    private func cellIndex(for event: NSEvent) -> Int? {
        let point = convert(event.locationInWindow, from: nil)
        switch page {
        case .days?: return geometry.index(at: point)
        case .picker?: return geometry.pickerIndex(at: point)
        case nil: return nil
        }
    }

    override func mouseMoved(with event: NSEvent) {
        hoveredIndex = cellIndex(for: event)
    }

    override func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
    }

    override func mouseDown(with event: NSEvent) {
        guard let page, let index = cellIndex(for: event) else { return }
        delegate?.gridView(self, didRequest: page.command(at: index))
    }

    override func keyDown(with event: NSEvent) {
        if delegate?.gridView(self, handle: Key(event: event)) != true {
            super.keyDown(with: event)
        }
    }

    override func scrollWheel(with event: NSEvent) {
        let steps = stepper.consume(deltaY: Double(event.scrollingDeltaY),
                                    isPrecise: event.hasPreciseScrollingDeltas,
                                    gestureEnded: event.phase == .ended || event.momentumPhase == .ended)
        if steps != 0 {
            delegate?.gridView(self, didScroll: steps)
        }
    }
}
