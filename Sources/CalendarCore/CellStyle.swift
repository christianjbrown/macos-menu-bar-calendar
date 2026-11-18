import Foundation

/// How one cell should look, decided without any drawing code.
public struct CellStyle: Equatable {
    public enum Background: Equatable { case none, today, hover }
    public enum Text: Equatable { case today, current, adjacent }

    public let background: Background
    public let outlined: Bool
    public let text: Text

    public init(isToday: Bool, isSelected: Bool, isHovered: Bool, isAdjacent: Bool) {
        background = isToday ? .today : (isHovered ? .hover : .none)
        outlined = isSelected && !isToday
        text = isToday ? .today : (isAdjacent ? .adjacent : .current)
    }

    /// A day in the month view. Days from the neighbouring months are dimmed.
    public init(day: Day, month: Month, today: Day, selected: Day, hovered: Day?) {
        self.init(isToday: day == today, isSelected: day == selected,
                  isHovered: day == hovered, isAdjacent: !month.contains(day))
    }

    /// A month or year in a picker.
    public init(item: PickerItem, isHovered: Bool) {
        self.init(isToday: item.isCurrent, isSelected: item.isSelected, isHovered: isHovered, isAdjacent: false)
    }
}
