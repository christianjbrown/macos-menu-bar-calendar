// Draws the Mac App Store screenshots: the real calendar view, rendered at high resolution
// under a menu bar, with a caption, in every language the app speaks.
//
// Usage: swift run StoreScreenshotTool <output folder>
// It needs a debug build (the default for `swift run`) for the @testable import.
import AppKit
import CalendarCore
@testable import MenuBarCalendarKit

/// The largest size the Mac App Store takes, in pixels.
let canvasPixels = NSSize(width: 2880, height: 1800)
/// Points to pixels, as on a Retina screen.
let canvasScale: CGFloat = 2
/// How much bigger than life the menu bar and calendar are drawn, so they read at store size.
let zoom: CGFloat = 2.4
let menuBarHeight: CGFloat = 24
let popoverCornerRadius: CGFloat = 10
let arrowSize = NSSize(width: 18, height: 9)
/// The icon sits this far in from the right of the menu bar, as if a few others sat beside it.
let iconInset: CGFloat = 420
let captionFontSize: CGFloat = 56
let captionInset: CGFloat = 110
/// Any day will do. This one is fictional and only picks which month is on show.
let shownDay = DateComponents(year: 2027, month: 5, day: 13, hour: 12)

struct FixedClock: Clock {
    let date: Date
    func now() -> Date { date }
}

struct Shot {
    let name: String
    let dark: Bool
    let command: CalendarCommand?
    let caption: KeyPath<Captions, String>
}

struct Captions {
    let days: String
    let months: String
    let years: String
    let dark: String
}

/// App Store Connect locale, app language, region for the calendar, and the captions.
let languages: [(store: String, app: String, locale: String, captions: Captions)] = [
    ("en-GB", "en", "en_GB", Captions(
        days: "The month, one click away", months: "Click the month to see the whole year",
        years: "Or zoom out to pick a year", dark: "Follows light and dark mode")),
    ("de-DE", "de", "de_DE", Captions(
        days: "Der Monat, einen Klick entfernt", months: "Ein Klick auf den Monat zeigt das ganze Jahr",
        years: "Oder weiter hinaus, um ein Jahr zu wählen", dark: "Passt sich dem hellen und dunklen Modus an")),
    ("fr-FR", "fr", "fr_FR", Captions(
        days: "Le mois, à un clic", months: "Cliquez sur le mois pour voir toute l’année",
        years: "Ou reculez encore pour choisir une année", dark: "Suit le mode clair et le mode sombre")),
    ("es-ES", "es", "es_ES", Captions(
        days: "El mes, a un clic", months: "Haz clic en el mes para ver todo el año",
        years: "O aleja la vista para elegir un año", dark: "Se adapta al modo claro y al oscuro")),
    ("nl-NL", "nl", "nl_NL", Captions(
        days: "De maand, één klik verwijderd", months: "Klik op de maand om het hele jaar te zien",
        years: "Of zoom verder uit om een jaar te kiezen", dark: "Volgt de lichte en donkere modus")),
    ("da", "da", "da_DK", Captions(
        days: "Måneden, ét klik væk", months: "Klik på måneden for at se hele året",
        years: "Eller zoom ud for at vælge et år", dark: "Følger lys og mørk tilstand")),
]

let shots = [
    Shot(name: "1-days", dark: false, command: nil, caption: \.days),
    Shot(name: "2-months", dark: false, command: .showMonths, caption: \.months),
    Shot(name: "3-years", dark: true, command: .showYears, caption: \.years),
    Shot(name: "4-dark", dark: true, command: nil, caption: \.dark),
]

struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let menuBar: NSColor
    let ink: NSColor
    let popover: NSColor

    static let light = Palette(
        backgroundTop: NSColor(srgbRed: 0.62, green: 0.78, blue: 0.98, alpha: 1),
        backgroundBottom: NSColor(srgbRed: 0.93, green: 0.95, blue: 0.99, alpha: 1),
        menuBar: NSColor(white: 1, alpha: 0.55), ink: .black, popover: NSColor(white: 0.97, alpha: 1))
    static let dark = Palette(
        backgroundTop: NSColor(srgbRed: 0.05, green: 0.09, blue: 0.22, alpha: 1),
        backgroundBottom: NSColor(srgbRed: 0.13, green: 0.16, blue: 0.27, alpha: 1),
        menuBar: NSColor(white: 0, alpha: 0.35), ink: .white, popover: NSColor(white: 0.16, alpha: 1))
}

@MainActor
func calendarImage(shot: Shot, strings: AppStrings, calendar: Calendar, appearance: NSAppearance) -> NSBitmapImageRep {
    let controller = CalendarViewController(clock: FixedClock(date: calendar.date(from: shownDay)!),
                                            calendar: calendar, strings: strings)
    let view = controller.view
    // The view takes its light or dark look from the window it sits in.
    let window = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
    window.appearance = appearance
    window.contentView = view
    if let command = shot.command {
        controller.gridView(controller.grid, didRequest: command)
    }
    view.layoutSubtreeIfNeeded()
    view.setFrameSize(view.fittingSize)
    view.layoutSubtreeIfNeeded()
    let size = view.bounds.size
    let sharp = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * zoom * canvasScale),
                                 pixelsHigh: Int(size.height * zoom * canvasScale), bitsPerSample: 8,
                                 samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    sharp.size = size
    appearance.performAsCurrentDrawingAppearance {
        view.cacheDisplay(in: view.bounds, to: sharp)
    }
    return sharp
}

@MainActor
func render(shot: Shot, strings: AppStrings, calendar: Calendar, caption: String) -> Data {
    let palette = shot.dark ? Palette.dark : Palette.light
    let appearance = NSAppearance(named: shot.dark ? .darkAqua : .aqua)!
    let calendarRep = calendarImage(shot: shot, strings: strings, calendar: calendar, appearance: appearance)

    let canvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(canvasPixels.width),
                                  pixelsHigh: Int(canvasPixels.height), bitsPerSample: 8, samplesPerPixel: 4,
                                  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                                  bytesPerRow: 0, bitsPerPixel: 0)!
    let size = NSSize(width: canvasPixels.width / canvasScale, height: canvasPixels.height / canvasScale)
    canvas.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    appearance.performAsCurrentDrawingAppearance {
        let bounds = NSRect(origin: .zero, size: size)
        NSGradient(starting: palette.backgroundBottom, ending: palette.backgroundTop)!.draw(in: bounds, angle: 90)

        // Menu bar, with the app's icon in it.
        let barHeight = menuBarHeight * zoom
        let bar = NSRect(x: 0, y: size.height - barHeight, width: size.width, height: barHeight)
        palette.menuBar.setFill()
        bar.fill()
        let icon = StatusIconRenderer.makeImage(description: strings.calendar)
        let iconSize = NSSize(width: icon.size.width * zoom, height: icon.size.height * zoom)
        let iconRect = NSRect(x: size.width - iconInset - iconSize.width / 2, y: bar.midY - iconSize.height / 2,
                              width: iconSize.width, height: iconSize.height)
        let tinted = NSImage(size: iconSize, flipped: false) { rect in
            icon.draw(in: rect)
            palette.ink.setFill()
            rect.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: iconRect)

        // The popover hanging from the icon.
        let content = NSSize(width: calendarRep.size.width * zoom, height: calendarRep.size.height * zoom)
        let arrow = NSSize(width: arrowSize.width * zoom, height: arrowSize.height * zoom)
        let top = bar.minY - 4 * zoom
        let body = NSRect(x: iconRect.midX - content.width / 2, y: top - arrow.height - content.height,
                          width: content.width, height: content.height)
        let shape = NSBezierPath(roundedRect: body, xRadius: popoverCornerRadius * zoom, yRadius: popoverCornerRadius * zoom)
        let point = NSBezierPath()
        point.move(to: NSPoint(x: iconRect.midX - arrow.width / 2, y: body.maxY - 1))
        point.line(to: NSPoint(x: iconRect.midX, y: top))
        point.line(to: NSPoint(x: iconRect.midX + arrow.width / 2, y: body.maxY - 1))
        point.close()
        shape.append(point)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(white: 0, alpha: 0.35)
        shadow.shadowBlurRadius = 30
        shadow.shadowOffset = NSSize(width: 0, height: -10)
        shadow.set()
        palette.popover.setFill()
        shape.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: body, xRadius: popoverCornerRadius * zoom, yRadius: popoverCornerRadius * zoom).addClip()
        // A bare draw(in:) copies, transparency and all, which would punch a hole in the popover.
        calendarRep.draw(in: body, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()

        // Caption, to the left of the popover.
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: captionFontSize, weight: .bold),
            .foregroundColor: palette.ink,
            .paragraphStyle: paragraph,
        ]
        let captionWidth = body.minX - captionInset * 2
        let text = NSAttributedString(string: caption, attributes: attributes)
        let textSize = text.boundingRect(with: NSSize(width: captionWidth, height: size.height),
                                         options: [.usesLineFragmentOrigin]).size
        text.draw(with: NSRect(x: captionInset, y: body.midY - textSize.height / 2,
                               width: captionWidth, height: textSize.height),
                  options: [.usesLineFragmentOrigin])
    }
    NSGraphicsContext.restoreGraphicsState()
    return canvas.representation(using: .png, properties: [:])!
}

MainActor.assumeIsolated {
    let output = URL(fileURLWithPath: CommandLine.arguments[1])
    for language in languages {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: language.locale)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let strings = AppStrings.byLanguage[language.app]!
        let folder = output.appendingPathComponent(language.store)
        try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for shot in shots {
            let png = render(shot: shot, strings: strings, calendar: calendar,
                             caption: language.captions[keyPath: shot.caption])
            try! png.write(to: folder.appendingPathComponent("\(shot.name).png"))
        }
    }
}
