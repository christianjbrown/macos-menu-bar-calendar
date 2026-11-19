import AppKit
import CalendarCore

/// Draws the app icon at any pixel size, straight from the vector shapes, so every size
/// in the .icns is rendered sharp rather than scaled from another bitmap.
enum AppIconRenderer {
    static let tileTop = NSColor(srgbRed: 0.35, green: 0.68, blue: 1.00, alpha: 1)
    static let tileBottom = NSColor(srgbRed: 0.16, green: 0.47, blue: 0.92, alpha: 1)
    static let glyphColour = NSColor.white
    static let shadowColour = NSColor(white: 0, alpha: 0.3)
    /// In canvas units, scaled with the icon.
    static let shadowDrop: CGFloat = 10
    static let shadowBlur: CGFloat = 20
    /// NSGradient angles run anticlockwise from the x axis; in the flipped canvas this runs top to bottom.
    static let topToBottom: CGFloat = 90

    static func pngData(pixels: Int) -> Data {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw(scale: CGFloat(pixels) / AppIconShape.canvas)
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])!
    }

    private static func draw(scale: CGFloat) {
        // Flip to the top-left origin the shapes use, and scale the canvas to the bitmap.
        let canvas = NSAffineTransform()
        canvas.translateX(by: 0, yBy: AppIconShape.canvas * scale)
        canvas.scaleX(by: scale, yBy: -scale)
        canvas.concat()

        let tile = NSBezierPath(roundedRect: AppIconShape.tile,
                                xRadius: AppIconShape.tileRadius, yRadius: AppIconShape.tileRadius)
        NSGraphicsContext.saveGraphicsState()
        // Shadows ignore the transform, so they are given in bitmap pixels, y up.
        let shadow = NSShadow()
        shadow.shadowColor = shadowColour
        shadow.shadowOffset = NSSize(width: 0, height: -shadowDrop * scale)
        shadow.shadowBlurRadius = shadowBlur * scale
        shadow.set()
        tileBottom.setFill()
        tile.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGradient(starting: tileTop, ending: tileBottom)!.draw(in: tile, angle: topToBottom)

        let glyph = CalendarGlyph.path()
        glyph.transform(using: AffineTransform(AppIconShape.glyphTransform))
        glyphColour.setFill()
        glyph.fill()
    }
}

private extension AffineTransform {
    init(_ t: CGAffineTransform) {
        self.init(m11: t.a, m12: t.b, m21: t.c, m22: t.d, tX: t.tx, tY: t.ty)
    }
}
