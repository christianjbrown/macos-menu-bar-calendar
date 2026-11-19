import CoreGraphics

/// The app icon's geometry, on Apple's 1024-unit macOS icon grid with a top-left origin:
/// a rounded tile with the menu bar icon's calendar page centred on it.
public enum AppIconShape {
    public static let canvas: CGFloat = 1024
    public static let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    public static let tileRadius: CGFloat = 185
    /// How wide the calendar page is drawn on the tile.
    public static let glyphWidth: CGFloat = 500

    /// Maps the menu bar icon's page onto the canvas, centred on the tile.
    public static var glyphTransform: CGAffineTransform {
        let page = StatusIconShape.page
        let scale = glyphWidth / page.width
        return CGAffineTransform(translationX: tile.midX - page.midX * scale, y: tile.midY - page.midY * scale)
            .scaledBy(x: scale, y: scale)
    }

    /// One image in an .iconset folder.
    public struct IconsetEntry: Equatable {
        public let fileName: String
        public let pixels: Int

        public init(fileName: String, pixels: Int) {
            self.fileName = fileName
            self.pixels = pixels
        }
    }

    /// The point sizes macOS asks an app icon for, each at 1x and 2x.
    public static let pointSizes = [16, 32, 128, 256, 512]
    public static let scales = [1, 2]

    public static var iconsetEntries: [IconsetEntry] {
        pointSizes.flatMap { points in
            scales.map { scale in
                let suffix = scale == 1 ? "" : "@\(scale)x"
                return IconsetEntry(fileName: "icon_\(points)x\(points)\(suffix).png", pixels: points * scale)
            }
        }
    }
}
