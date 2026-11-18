import CoreGraphics

/// Where the weekday headers and date cells sit, in flipped (top-left origin) coordinates.
public struct GridGeometry: Equatable {
    public static let standard = GridGeometry(cellSize: CGSize(width: 28, height: 24), headerHeight: 20)

    public let cellSize: CGSize
    public let headerHeight: CGFloat

    public init(cellSize: CGSize, headerHeight: CGFloat) {
        self.cellSize = cellSize
        self.headerHeight = headerHeight
    }

    public var size: CGSize {
        CGSize(width: cellSize.width * CGFloat(MonthGrid.columns),
               height: headerHeight + cellSize.height * CGFloat(MonthGrid.rows))
    }

    public var separatorRect: CGRect {
        CGRect(x: 0, y: headerHeight - 1, width: size.width, height: 1)
    }

    public func headerRect(column: Int) -> CGRect {
        CGRect(x: CGFloat(column) * cellSize.width, y: 3, width: cellSize.width, height: headerHeight)
    }

    public func cellRect(index: Int) -> CGRect {
        CGRect(x: CGFloat(index % MonthGrid.columns) * cellSize.width,
               y: headerHeight + CGFloat(index / MonthGrid.columns) * cellSize.height,
               width: cellSize.width, height: cellSize.height)
    }

    /// A month or year cell in the picker, which uses the whole area, headers included.
    public func pickerCellRect(index: Int) -> CGRect {
        let width = size.width / CGFloat(PickerGrid.columns)
        let height = size.height / CGFloat(PickerGrid.rows)
        return CGRect(x: CGFloat(index % PickerGrid.columns) * width,
                      y: CGFloat(index / PickerGrid.columns) * height, width: width, height: height)
    }

    /// The picker cell under a point, or nil outside the grid.
    public func pickerIndex(at point: CGPoint) -> Int? {
        guard CGRect(origin: .zero, size: size).contains(point) else { return nil }
        let row = Int(point.y / (size.height / CGFloat(PickerGrid.rows)))
        let column = Int(point.x / (size.width / CGFloat(PickerGrid.columns)))
        return row * PickerGrid.columns + column
    }

    /// The day cell under a point, or nil over the headers or outside the grid.
    public func index(at point: CGPoint) -> Int? {
        let cells = CGRect(x: 0, y: headerHeight, width: size.width, height: size.height - headerHeight)
        guard cells.contains(point) else { return nil }
        let row = Int((point.y - headerHeight) / cellSize.height)
        let column = Int(point.x / cellSize.width)
        return row * MonthGrid.columns + column
    }
}
