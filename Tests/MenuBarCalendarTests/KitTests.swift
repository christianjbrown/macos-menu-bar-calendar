import AppKit
import CalendarCore
@testable import MenuBarCalendarKit

@MainActor
func kitTests() {
    let t = TestRun.shared
    let calendar = gregorian()
    let today = Day(year: 2026, month: 11, day: 18)

    // MARK: Palette

    t.run("Palette", "uses a different today colour in light and dark mode") {
        var light: NSColor?
        var dark: NSColor?
        NSAppearance(named: .aqua)!.performAsCurrentDrawingAppearance { light = Palette.today.usingColorSpace(.sRGB) }
        NSAppearance(named: .darkAqua)!.performAsCurrentDrawingAppearance { dark = Palette.today.usingColorSpace(.sRGB) }
        try expectEqual(light!.blueComponent, 1.0)
        try expect(abs(dark!.blueComponent - 0.9) < 0.001)
    }
    t.run("Palette", "maps every cell style to colours and fonts") {
        try expectEqual(Palette.background(.none), nil)
        try expect(Palette.background(.today) === Palette.today)
        try expectEqual(Palette.background(.hover), .quaternaryLabelColor)
        try expectEqual(Palette.textColor(.today), .white)
        try expectEqual(Palette.textColor(.current), .labelColor)
        try expectEqual(Palette.textColor(.adjacent), .tertiaryLabelColor)
        try expect(Palette.font(.today, size: 12) != Palette.font(.current, size: 12))
        try expectEqual(Palette.font(.adjacent, size: 13).pointSize, 13)
    }

    // MARK: StatusIconRenderer

    t.run("StatusIconRenderer", "draws a template calendar icon with dots") {
        let image = StatusIconRenderer.makeImage(description: "Kalender")
        try expect(image.isTemplate)
        try expectEqual(image.size, StatusIconShape.size)
        try expectEqual(image.accessibilityDescription, "Kalender")

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 21, pixelsHigh: 16, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        // Bitmap rows run top-down, matching the flipped icon geometry.
        try expect(rep.colorAt(x: 10, y: 1)!.alphaComponent > 0.9, "header band is solid")
        try expect(rep.colorAt(x: 9, y: 6)!.alphaComponent > 0.5, "first dot is drawn")
        try expect(rep.colorAt(x: 6, y: 6)!.alphaComponent < 0.1, "first row starts mid-week")
    }

    // MARK: AppIconRenderer

    t.run("AppIconRenderer", "draws a white calendar page on a blue tile") {
        let rep = NSBitmapImageRep(data: AppIconRenderer.pngData(pixels: 1024))!
        try expectEqual(rep.pixelsWide, 1024)
        try expectEqual(rep.pixelsHigh, 1024)
        let corner = rep.colorAt(x: 2, y: 2)!
        try expect(corner.alphaComponent < 0.01, "outside the tile is clear")
        let tile = rep.colorAt(x: 150, y: 512)!.usingColorSpace(.sRGB)!
        try expect(tile.blueComponent > 0.9 && tile.redComponent < 0.5, "tile is blue")
        // The header band sits above the tile's centre, the empty first day cell to the left of the dots.
        let header = rep.colorAt(x: 512, y: 320)!.usingColorSpace(.sRGB)!
        try expect(header.redComponent > 0.99 && header.blueComponent > 0.99, "header band is white")
        let firstCell = rep.colorAt(x: 380, y: 452)!.usingColorSpace(.sRGB)!
        try expect(firstCell.redComponent < 0.5, "first row starts mid-week")
    }
    t.run("AppIconWriter", "writes every image of the iconset") {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try AppIconWriter.writeIconset(to: directory)
        for entry in AppIconShape.iconsetEntries {
            let rep = NSBitmapImageRep(data: try Data(contentsOf: directory.appendingPathComponent(entry.fileName)))!
            try expectEqual(rep.pixelsWide, entry.pixels, entry.fileName)
        }
    }

    // MARK: Event translation

    t.run("Key", "reads arrows and page keys from key events") {
        let cases: [(Int, Key)] = [(NSLeftArrowFunctionKey, .left), (NSRightArrowFunctionKey, .right),
                                   (NSUpArrowFunctionKey, .up), (NSDownArrowFunctionKey, .down),
                                   (NSPageUpFunctionKey, .pageUp), (NSPageDownFunctionKey, .pageDown)]
        for (code, key) in cases {
            try expectEqual(Key(event: keyEvent(String(UnicodeScalar(code)!))), key)
        }
        try expectEqual(Key(event: keyEvent("t")), .other("t"))
    }
    t.run("ClickClassifier", "treats right and control clicks as secondary") {
        try expect(!ClickClassifier.isSecondary(nil))
        try expect(ClickClassifier.isSecondary(mouseEvent(.rightMouseUp)))
        try expect(ClickClassifier.isSecondary(mouseEvent(.leftMouseUp, modifiers: .control)))
        try expect(!ClickClassifier.isSecondary(mouseEvent(.leftMouseUp)))
    }

    // MARK: CalendarGridView

    func makeGrid() -> (CalendarGridView, NSWindow, FakeGridDelegate) {
        let grid = CalendarGridView(frame: NSRect(origin: .zero, size: GridGeometry.standard.size))
        let container = NSView(frame: grid.frame)
        container.addSubview(grid)
        let window = hostWindow(for: container, size: grid.frame.size)
        let delegate = FakeGridDelegate()
        grid.delegate = delegate
        return (grid, window, delegate)
    }
    func windowPoint(_ grid: CalendarGridView, _ point: NSPoint) -> NSPoint {
        grid.convert(point, to: nil)
    }
    func render(_ view: NSView, appearance: NSAppearance.Name = .aqua) -> NSBitmapImageRep {
        view.appearance = NSAppearance(named: appearance)
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep
    }
    let daysPage = CalendarPage(state: CalendarState(today: today), calendar: calendar)
    var pickedState = CalendarState(today: today)
    pickedState.apply(.showMonths, calendar: calendar)
    let monthsPage = CalendarPage(state: pickedState, calendar: calendar)

    t.run("CalendarGridView", "reports its fixed size and responder traits") {
        let (grid, _, _) = makeGrid()
        try expect(grid.isFlipped)
        try expect(grid.acceptsFirstResponder)
        try expectEqual(grid.intrinsicContentSize, GridGeometry.standard.size)
    }
    t.run("CalendarGridView", "draws nothing before it has a page") {
        let (grid, _, _) = makeGrid()
        let rep = render(grid)
        try expect(rep.colorAt(x: 20, y: 40)!.alphaComponent < 0.01)
    }
    t.run("CalendarGridView", "draws days with today filled, in light and dark mode") {
        let (grid, window, _) = makeGrid()
        var state = CalendarState(today: today)
        state.apply(.select(Day(year: 2026, month: 11, day: 3)), calendar: calendar)
        grid.page = CalendarPage(state: state, calendar: calendar)
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: windowPoint(grid, NSPoint(x: 10, y: 30)), in: window))
        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            let rep = render(grid, appearance: appearance)
            // 18 Nov is index 23: row 3, column 2. Sample the left edge of its pill.
            let todayCell = GridGeometry.standard.cellRect(index: 23)
            let scale = CGFloat(rep.pixelsWide) / grid.bounds.width
            let pixel = rep.colorAt(x: Int((todayCell.minX + 4) * scale), y: Int(todayCell.midY * scale))!
                .usingColorSpace(.sRGB)!
            try expect(pixel.blueComponent > 0.8 && pixel.blueComponent - pixel.redComponent > 0.4, "today is blue in \(appearance): \(pixel)")
        }
    }
    t.run("CalendarGridView", "draws the month picker with hover") {
        let (grid, window, _) = makeGrid()
        grid.page = monthsPage
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: windowPoint(grid, NSPoint(x: 10, y: 10)), in: window))
        try expectEqual(grid.hoveredIndex, 0)
        let rep = render(grid)
        try expect(rep.colorAt(x: 20, y: 20)!.alphaComponent > 0, "January is shaded")
    }
    t.run("CalendarGridView", "tracks hover and clears it on exit and page change") {
        let (grid, window, _) = makeGrid()
        let point = windowPoint(grid, NSPoint(x: 30, y: 50))
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: point, in: window))
        try expectEqual(grid.hoveredIndex, nil, "no page, no hover")
        grid.page = daysPage
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: point, in: window))
        try expectEqual(grid.hoveredIndex, 8)
        grid.displayIfNeeded()
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: point, in: window))
        try expect(!grid.needsDisplay, "same cell does not redraw")
        grid.mouseExited(with: exitEvent(in: window))
        try expectEqual(grid.hoveredIndex, nil)
        grid.mouseMoved(with: mouseEvent(.mouseMoved, at: point, in: window))
        grid.page = monthsPage
        try expectEqual(grid.hoveredIndex, nil)
    }
    t.run("CalendarGridView", "turns clicks into commands for days and pickers") {
        let (grid, window, delegate) = makeGrid()
        grid.mouseDown(with: mouseEvent(.leftMouseDown, at: windowPoint(grid, NSPoint(x: 30, y: 50)), in: window))
        try expect(delegate.commands.isEmpty, "no page, no command")
        grid.page = daysPage
        grid.mouseDown(with: mouseEvent(.leftMouseDown, at: windowPoint(grid, NSPoint(x: 10, y: 5)), in: window))
        try expect(delegate.commands.isEmpty, "header click does nothing")
        grid.mouseDown(with: mouseEvent(.leftMouseDown, at: windowPoint(grid, NSPoint(x: 30, y: 50)), in: window))
        try expectEqual(delegate.commands, [.select(Day(year: 2026, month: 11, day: 3))])
        grid.page = monthsPage
        grid.mouseDown(with: mouseEvent(.leftMouseDown, at: windowPoint(grid, NSPoint(x: 190, y: 160)), in: window))
        try expectEqual(delegate.commands.last!, .pickMonth(Month(year: 2026, month: 12)))
    }
    t.run("CalendarGridView", "passes keys to the delegate, then up the chain if unhandled") {
        let (grid, _, delegate) = makeGrid()
        let catcher = KeyCatcher()
        grid.nextResponder = catcher
        grid.keyDown(with: keyEvent("t"))
        try expectEqual(delegate.keys, [.other("t")])
        try expectEqual(catcher.caught, 0)
        delegate.handles = false
        grid.keyDown(with: keyEvent("x"))
        try expectEqual(catcher.caught, 1)
        grid.delegate = nil
        grid.keyDown(with: keyEvent("x"))
        try expectEqual(catcher.caught, 2)
    }
    t.run("CalendarGridView", "turns wheel and trackpad scrolling into steps") {
        let (grid, _, delegate) = makeGrid()
        grid.scrollWheel(with: scrollEvent(lines: 1))
        try expectEqual(delegate.scrolled, [-1])
        grid.scrollWheel(with: scrollEvent(pixels: 10, phase: 2))
        try expectEqual(delegate.scrolled, [-1], "small trackpad move waits")
        grid.scrollWheel(with: scrollEvent(pixels: 10, phase: 4))
        grid.scrollWheel(with: scrollEvent(pixels: 25, momentumPhase: 3))
        grid.scrollWheel(with: scrollEvent(pixels: 25, phase: 2))
        try expectEqual(delegate.scrolled, [-1], "leftovers were dropped when each gesture ended")
        grid.scrollWheel(with: scrollEvent(pixels: -70, phase: 2))
        try expectEqual(delegate.scrolled, [-1, 1])
    }
    t.run("CalendarGridView", "redraws on appearance change and keeps one tracking area") {
        let (grid, _, _) = makeGrid()
        grid.displayIfNeeded()
        grid.viewDidChangeEffectiveAppearance()
        try expect(grid.needsDisplay)
        grid.updateTrackingAreas()
        grid.updateTrackingAreas()
        try expectEqual(grid.trackingAreas.count, 1)
    }
}
