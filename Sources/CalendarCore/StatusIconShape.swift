import CoreGraphics

/// The menu bar icon's geometry: a calendar page with a solid header band and a grid of dots.
/// Coordinates are flipped (top-left origin) in points.
/// Adapted from the `calendar3` icon in Bootstrap Icons (MIT, see Support/Licenses/bootstrap-icons.txt).
public enum StatusIconShape {
    public static let size = CGSize(width: 21, height: 16)
    public static let page = CGRect(x: 2, y: 0, width: 17, height: 16)
    public static let pageRadius: CGFloat = 2.5
    public static let window = CGRect(x: 3.5, y: 3.5, width: 14, height: 11)
    public static let windowRadius: CGFloat = 0.75
    public static let dotRadius: CGFloat = 0.4

    /// Which of the four columns has a dot on each row: the month starts mid-week,
    /// then a full week, then a short last row.
    public static let dotColumns = [[1, 2, 3], [0, 1, 2, 3], [0, 1, 2]]

    public static var dots: [CGRect] {
        dotColumns.enumerated().flatMap { row, columns in
            columns.map { CGRect(x: 5 + CGFloat($0) * 3, y: 5 + CGFloat(row) * 3, width: 2, height: 2) }
        }
    }
}
