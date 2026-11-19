import CalendarCore
import CoreGraphics
import Foundation

@MainActor
func coreTests() {
    let t = TestRun.shared
    let monday = gregorian(firstWeekday: 2)
    let sunday = gregorian(firstWeekday: 1)

    // MARK: Day

    t.run("Day", "builds from a date in the calendar's time zone") {
        try expectEqual(Day(date(2026, 11, 18, hour: 0), calendar: monday), Day(year: 2026, month: 11, day: 18))
        try expectEqual(Day(date(2026, 11, 18, hour: 23), calendar: monday), Day(year: 2026, month: 11, day: 18))
    }
    t.run("Day", "round-trips through a date at midday") {
        let day = Day(year: 2026, month: 3, day: 29)
        try expectEqual(Day(day.date(in: monday), calendar: monday), day)
        try expectEqual(monday.component(.hour, from: day.date(in: monday)), 12)
    }
    t.run("Day", "adds days across months, years and leap days") {
        try expectEqual(Day(year: 2026, month: 12, day: 31).adding(days: 1, calendar: monday), Day(year: 2027, month: 1, day: 1))
        try expectEqual(Day(year: 2028, month: 2, day: 28).adding(days: 1, calendar: monday), Day(year: 2028, month: 2, day: 29))
        try expectEqual(Day(year: 2026, month: 1, day: 1).adding(days: -1, calendar: monday), Day(year: 2025, month: 12, day: 31))
    }
    t.run("Day", "does not skip or repeat days at the clock changes") {
        try expectEqual(Day(year: 2026, month: 10, day: 25).adding(days: 1, calendar: monday), Day(year: 2026, month: 10, day: 26))
        try expectEqual(Day(year: 2026, month: 3, day: 29).adding(days: -1, calendar: monday), Day(year: 2026, month: 3, day: 28))
    }
    t.run("Day", "describes itself as an ISO date") {
        try expectEqual(Day(year: 2026, month: 1, day: 5).description, "2026-01-05")
    }

    // MARK: Month

    t.run("Month", "builds from a day and knows its first day") {
        let month = Month(Day(year: 2026, month: 11, day: 18))
        try expectEqual(month, Month(year: 2026, month: 11))
        try expectEqual(month.firstDay, Day(year: 2026, month: 11, day: 1))
    }
    t.run("Month", "adds months across year boundaries in both directions") {
        try expectEqual(Month(year: 2026, month: 12).adding(months: 1), Month(year: 2027, month: 1))
        try expectEqual(Month(year: 2026, month: 1).adding(months: -1), Month(year: 2025, month: 12))
        try expectEqual(Month(year: 2026, month: 5).adding(months: -17), Month(year: 2024, month: 12))
        try expectEqual(Month(year: 2026, month: 5).adding(months: 0), Month(year: 2026, month: 5))
    }
    t.run("Month", "contains only its own days") {
        let month = Month(year: 2026, month: 11)
        try expect(month.contains(Day(year: 2026, month: 11, day: 30)))
        try expect(!month.contains(Day(year: 2026, month: 12, day: 1)), "other month, same year")
        try expect(!month.contains(Day(year: 2025, month: 11, day: 1)), "same month, other year")
    }

    // MARK: MonthGrid

    t.run("MonthGrid", "starts on the calendar's first weekday") {
        let mondayGrid = MonthGrid(month: Month(year: 2026, month: 11), calendar: monday)
        try expectEqual(mondayGrid.days.count, 42)
        try expectEqual(mondayGrid.days.first!, Day(year: 2026, month: 10, day: 26))
        try expectEqual(mondayGrid.days[6], Day(year: 2026, month: 11, day: 1))
        try expectEqual(mondayGrid.weekdaySymbols, ["M", "T", "W", "T", "F", "S", "S"])

        let sundayGrid = MonthGrid(month: Month(year: 2026, month: 11), calendar: sunday)
        try expectEqual(sundayGrid.days.first!, Day(year: 2026, month: 11, day: 1))
        try expectEqual(sundayGrid.weekdaySymbols.first!, "S")
    }
    t.run("MonthGrid", "has consecutive days and always holds the whole month") {
        for year in 2024...2030 {
            for number in 1...12 {
                let grid = MonthGrid(month: Month(year: year, month: number), calendar: monday)
                for (a, b) in zip(grid.days, grid.days.dropFirst()) {
                    try expectEqual(a.adding(days: 1, calendar: monday), b)
                }
                let inMonth = grid.days.filter { grid.month.contains($0) }
                try expectEqual(inMonth.first!.day, 1)
                try expect(inMonth.count >= 28)
            }
        }
    }

    // MARK: CalendarState

    let today = Day(year: 2026, month: 11, day: 18)

    t.run("CalendarState", "starts on today") {
        let state = CalendarState(today: today)
        try expectEqual(state.today, today)
        try expectEqual(state.selected, today)
        try expectEqual(state.month, Month(year: 2026, month: 11))
        try expectEqual(state.mode, .days)
        try expectEqual(state.years, 2021..<2033)
    }
    t.run("CalendarState", "changes month without moving the selection") {
        var state = CalendarState(today: today)
        state.apply(.step(2), calendar: monday)
        try expectEqual(state.month, Month(year: 2027, month: 1))
        try expectEqual(state.selected, today)
    }
    t.run("CalendarState", "moves the selection, following it into the next month") {
        var state = CalendarState(today: today)
        state.apply(.moveSelection(days: 7), calendar: monday)
        try expectEqual(state.selected, Day(year: 2026, month: 11, day: 25))
        try expectEqual(state.month, Month(year: 2026, month: 11))
        state.apply(.moveSelection(days: 7), calendar: monday)
        try expectEqual(state.selected, Day(year: 2026, month: 12, day: 2))
        try expectEqual(state.month, Month(year: 2026, month: 12))
    }
    t.run("CalendarState", "selects a clicked day") {
        var state = CalendarState(today: today)
        state.apply(.select(Day(year: 2026, month: 10, day: 30)), calendar: monday)
        try expectEqual(state.selected, Day(year: 2026, month: 10, day: 30))
        try expectEqual(state.month, Month(year: 2026, month: 10))
    }
    t.run("CalendarState", "moves a selection that was on today when the day rolls over") {
        var state = CalendarState(today: Day(year: 2026, month: 11, day: 30))
        state.updateToday(Day(year: 2026, month: 12, day: 1))
        try expectEqual(state.selected, Day(year: 2026, month: 12, day: 1))
        try expectEqual(state.month, Month(year: 2026, month: 12))
    }
    t.run("CalendarState", "leaves a chosen selection alone when the day rolls over") {
        var state = CalendarState(today: today)
        state.apply(.select(Day(year: 2026, month: 11, day: 3)), calendar: monday)
        state.updateToday(Day(year: 2026, month: 11, day: 19))
        try expectEqual(state.today, Day(year: 2026, month: 11, day: 19))
        try expectEqual(state.selected, Day(year: 2026, month: 11, day: 3))
    }

    t.run("CalendarState", "zooms out to the months of the displayed year") {
        var state = CalendarState(today: today)
        state.apply(.step(2), calendar: monday)
        state.apply(.showMonths, calendar: monday)
        try expectEqual(state.mode, .months)
        try expectEqual(state.month, Month(year: 2027, month: 1))
    }
    t.run("CalendarState", "steps a year at a time in the months view") {
        var state = CalendarState(today: today)
        state.apply(.showMonths, calendar: monday)
        state.apply(.step(-1), calendar: monday)
        try expectEqual(state.month, Month(year: 2025, month: 11))
        try expectEqual(state.mode, .months)
    }
    t.run("CalendarState", "opens a page of years centred on the displayed year") {
        var state = CalendarState(today: today)
        state.apply(.step(-12), calendar: monday)
        state.apply(.showYears, calendar: monday)
        try expectEqual(state.mode, .years)
        try expectEqual(state.years, 2020..<2032)
    }
    t.run("CalendarState", "steps six years at a time in the years view") {
        var state = CalendarState(today: today)
        state.apply(.showYears, calendar: monday)
        state.apply(.step(1), calendar: monday)
        try expectEqual(state.years, 2027..<2039)
        state.apply(.step(-2), calendar: monday)
        try expectEqual(state.years, 2015..<2027)
        try expectEqual(state.month, Month(year: 2026, month: 11))
    }
    t.run("CalendarState", "picks a year, then a month, back down to the days") {
        var state = CalendarState(today: today)
        state.apply(.showYears, calendar: monday)
        state.apply(.pickYear(2030), calendar: monday)
        try expectEqual(state.mode, .months)
        try expectEqual(state.month, Month(year: 2030, month: 11))
        state.apply(.pickMonth(Month(year: 2030, month: 2)), calendar: monday)
        try expectEqual(state.mode, .days)
        try expectEqual(state.month, Month(year: 2030, month: 2))
        try expectEqual(state.selected, today)
    }
    t.run("CalendarState", "ignores arrow keys outside the days view") {
        var state = CalendarState(today: today)
        state.apply(.showMonths, calendar: monday)
        state.apply(.moveSelection(days: 1), calendar: monday)
        try expectEqual(state.selected, today)
        try expectEqual(state.mode, .months)
    }
    t.run("CalendarState", "keeps the zoom level when the day rolls over") {
        var state = CalendarState(today: Day(year: 2026, month: 11, day: 30))
        state.apply(.showYears, calendar: monday)
        state.updateToday(Day(year: 2026, month: 12, day: 1))
        try expectEqual(state.mode, .years)
        try expectEqual(state.selected, Day(year: 2026, month: 12, day: 1))
        try expectEqual(state.month, Month(year: 2026, month: 11))
    }

    // MARK: CalendarPage, pickers and header

    t.run("PickerGrid", "lists the months of a year with today and the displayed month marked") {
        let picker = PickerGrid.months(of: 2026, displayed: Month(year: 2026, month: 3), today: today, calendar: monday)
        try expectEqual(picker.items.map(\.label), ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
        try expectEqual(picker.items.filter(\.isCurrent).map(\.label), ["Nov"])
        try expectEqual(picker.items.filter(\.isSelected).map(\.label), ["Mar"])
        try expectEqual(picker.items[1].command, .pickMonth(Month(year: 2026, month: 2)))
        let otherYear = PickerGrid.months(of: 2027, displayed: Month(year: 2026, month: 3), today: today, calendar: monday)
        try expect(otherYear.items.allSatisfy { !$0.isCurrent && !$0.isSelected })
    }
    t.run("PickerGrid", "lists twelve years with today's year and the displayed year marked") {
        let picker = PickerGrid.years(2021..<2033, displayed: 2024, today: today)
        try expectEqual(picker.items.count, 12)
        try expectEqual(picker.items.first!.label, "2021")
        try expectEqual(picker.items.last!.label, "2032")
        try expectEqual(picker.items.filter(\.isCurrent).map(\.label), ["2026"])
        try expectEqual(picker.items.filter(\.isSelected).map(\.label), ["2024"])
        try expectEqual(picker.items[0].command, .pickYear(2021))
    }
    t.run("CalendarPage", "shows days, months or years to match the zoom level") {
        var state = CalendarState(today: today)
        try expectEqual(CalendarPage(state: state, calendar: monday),
                        .days(MonthGrid(month: state.month, calendar: monday), today: today, selected: today))
        state.apply(.showMonths, calendar: monday)
        try expectEqual(CalendarPage(state: state, calendar: monday),
                        .picker(.months(of: 2026, displayed: state.month, today: today, calendar: monday)))
        state.apply(.showYears, calendar: monday)
        try expectEqual(CalendarPage(state: state, calendar: monday),
                        .picker(.years(2021..<2033, displayed: 2026, today: today)))
    }
    t.run("CalendarPage", "turns a clicked cell into a command") {
        let days = CalendarPage(state: CalendarState(today: today), calendar: monday)
        try expectEqual(days.command(at: 0), .select(Day(year: 2026, month: 10, day: 26)))
        let years = CalendarPage.picker(.years(2021..<2033, displayed: 2026, today: today))
        try expectEqual(years.command(at: 11), .pickYear(2032))
    }
    t.run("CalendarHeader", "titles each zoom level") {
        var state = CalendarState(today: today)
        try expectEqual(CalendarHeader.parts(for: state, calendar: monday), [
            HeaderPart(text: "November", command: .showMonths),
            HeaderPart(text: "2026", command: .showYears),
        ])
        state.apply(.showMonths, calendar: monday)
        try expectEqual(CalendarHeader.parts(for: state, calendar: monday), [HeaderPart(text: "2026", command: .showYears)])
        state.apply(.showYears, calendar: monday)
        try expectEqual(CalendarHeader.parts(for: state, calendar: monday), [HeaderPart(text: "2021 - 2032", command: nil)])
    }

    // MARK: KeyMap

    t.run("KeyMap", "maps arrows and page keys to commands") {
        try expectEqual(KeyMap.action(for: .left), .command(.moveSelection(days: -1)))
        try expectEqual(KeyMap.action(for: .right), .command(.moveSelection(days: 1)))
        try expectEqual(KeyMap.action(for: .up), .command(.moveSelection(days: -7)))
        try expectEqual(KeyMap.action(for: .down), .command(.moveSelection(days: 7)))
        try expectEqual(KeyMap.action(for: .pageUp), .command(.step(-1)))
        try expectEqual(KeyMap.action(for: .pageDown), .command(.step(1)))
    }
    t.run("KeyMap", "maps Escape and ignores everything else") {
        try expectEqual(KeyMap.action(for: .other("t")), nil)
        try expectEqual(KeyMap.action(for: .other("\u{1b}")), .dismiss)
        try expectEqual(KeyMap.action(for: .other("x")), nil)
        try expectEqual(KeyMap.action(for: .other(nil)), nil)
    }

    // MARK: ScrollStepper

    t.run("ScrollStepper", "steps one month per mouse wheel notch") {
        var stepper = ScrollStepper()
        try expectEqual(stepper.consume(deltaY: 1, isPrecise: false, gestureEnded: false), -1)
        try expectEqual(stepper.consume(deltaY: -2, isPrecise: false, gestureEnded: false), 2)
    }
    t.run("ScrollStepper", "accumulates trackpad deltas up to the threshold") {
        var stepper = ScrollStepper()
        try expectEqual(stepper.consume(deltaY: 20, isPrecise: true, gestureEnded: false), 0)
        try expectEqual(stepper.consume(deltaY: 20, isPrecise: true, gestureEnded: false), -1)
        try expectEqual(stepper.consume(deltaY: 15, isPrecise: true, gestureEnded: false), 0)
        try expectEqual(stepper.consume(deltaY: 5, isPrecise: true, gestureEnded: false), -1)
    }
    t.run("ScrollStepper", "forgets leftovers when the gesture ends") {
        var stepper = ScrollStepper()
        try expectEqual(stepper.consume(deltaY: 25, isPrecise: true, gestureEnded: true), 0)
        try expectEqual(stepper.consume(deltaY: 25, isPrecise: true, gestureEnded: false), 0)
    }

    // MARK: GridGeometry

    let geometry = GridGeometry.standard
    t.run("GridGeometry", "sizes the grid from its cells") {
        try expectEqual(geometry.size, CGSize(width: 196, height: 164))
        try expectEqual(geometry.separatorRect, CGRect(x: 0, y: 19, width: 196, height: 1))
        try expectEqual(geometry.headerRect(column: 2), CGRect(x: 56, y: 3, width: 28, height: 20))
    }
    t.run("GridGeometry", "places cells row by row") {
        try expectEqual(geometry.cellRect(index: 0), CGRect(x: 0, y: 20, width: 28, height: 24))
        try expectEqual(geometry.cellRect(index: 8), CGRect(x: 28, y: 44, width: 28, height: 24))
    }
    t.run("GridGeometry", "finds the cell under a point") {
        try expectEqual(geometry.index(at: CGPoint(x: 1, y: 21)), 0)
        try expectEqual(geometry.index(at: CGPoint(x: 195, y: 163)), 41)
        try expectEqual(geometry.index(at: CGPoint(x: 30, y: 50)), 8)
    }
    t.run("GridGeometry", "finds nothing over the headers or outside") {
        try expectEqual(geometry.index(at: CGPoint(x: 10, y: 5)), nil)
        try expectEqual(geometry.index(at: CGPoint(x: -1, y: 30)), nil)
        try expectEqual(geometry.index(at: CGPoint(x: 196, y: 30)), nil)
        try expectEqual(geometry.index(at: CGPoint(x: 10, y: 164)), nil)
    }

    t.run("GridGeometry", "lays the pickers out four across and three down") {
        try expectEqual(geometry.pickerCellRect(index: 0), CGRect(x: 0, y: 0, width: 49, height: 164.0 / 3))
        try expectEqual(geometry.pickerCellRect(index: 5).origin, CGPoint(x: 49, y: 164.0 / 3))
        try expectEqual(geometry.pickerIndex(at: CGPoint(x: 1, y: 1)), 0)
        try expectEqual(geometry.pickerIndex(at: CGPoint(x: 195, y: 163)), 11)
        try expectEqual(geometry.pickerIndex(at: CGPoint(x: 50, y: 60)), 5)
        try expectEqual(geometry.pickerIndex(at: CGPoint(x: -1, y: 10)), nil)
        try expectEqual(geometry.pickerIndex(at: CGPoint(x: 10, y: 164)), nil)
    }

    // MARK: CellStyle

    let month = Month(year: 2026, month: 11)
    let selected = Day(year: 2026, month: 11, day: 3)
    func style(_ day: Day, hovered: Day? = nil) -> CellStyle {
        CellStyle(day: day, month: month, today: today, selected: selected, hovered: hovered)
    }
    t.run("CellStyle", "fills today and never outlines it") {
        let todayStyle = CellStyle(day: today, month: month, today: today, selected: today, hovered: today)
        try expectEqual(todayStyle.background, .today)
        try expectEqual(todayStyle.text, .today)
        try expect(!todayStyle.outlined)
    }
    t.run("CellStyle", "outlines the selection and shades the hovered day") {
        try expect(style(selected).outlined)
        try expectEqual(style(selected).background, .none)
        try expectEqual(style(Day(year: 2026, month: 11, day: 9), hovered: Day(year: 2026, month: 11, day: 9)).background, .hover)
    }
    t.run("CellStyle", "dims days from the neighbouring months") {
        try expectEqual(style(Day(year: 2026, month: 11, day: 9)).text, .current)
        try expectEqual(style(Day(year: 2026, month: 12, day: 2)).text, .adjacent)
        try expect(!style(Day(year: 2026, month: 12, day: 2)).outlined)
    }

    t.run("CellStyle", "styles picker items like days") {
        let current = PickerItem(label: "Nov", command: .showMonths, isCurrent: true, isSelected: true)
        try expectEqual(CellStyle(item: current, isHovered: true), CellStyle(isToday: true, isSelected: true, isHovered: true, isAdjacent: false))
        let picked = PickerItem(label: "Mar", command: .showMonths, isCurrent: false, isSelected: true)
        let style = CellStyle(item: picked, isHovered: true)
        try expectEqual(style.background, .hover)
        try expect(style.outlined)
        try expectEqual(style.text, .current)
    }

    // MARK: StatusIconShape

    t.run("StatusIconShape", "lays the dots out three, four, three") {
        let dots = StatusIconShape.dots
        try expectEqual(dots.count, 10)
        try expectEqual(dots.first!, CGRect(x: 8, y: 5, width: 2, height: 2))
        try expectEqual(dots[3], CGRect(x: 5, y: 8, width: 2, height: 2))
        try expectEqual(dots.last!, CGRect(x: 11, y: 11, width: 2, height: 2))
        for dot in dots {
            try expect(StatusIconShape.window.contains(dot), "\(dot) sits inside the page")
        }
        try expect(StatusIconShape.page.contains(StatusIconShape.window))
        try expectEqual(StatusIconShape.size, CGSize(width: 21, height: 16))
    }

    // MARK: AppIconShape

    t.run("AppIconShape", "centres the calendar page on the tile") {
        let glyph = StatusIconShape.page.applying(AppIconShape.glyphTransform)
        try expect(abs(glyph.midX - AppIconShape.tile.midX) < 0.001)
        try expect(abs(glyph.midY - AppIconShape.tile.midY) < 0.001)
        try expect(abs(glyph.width - AppIconShape.glyphWidth) < 0.001)
        try expect(AppIconShape.tile.contains(glyph))
    }
    t.run("AppIconShape", "lists every size an .iconset needs") {
        let entries = AppIconShape.iconsetEntries
        try expectEqual(entries.count, 10)
        try expectEqual(entries.first!, AppIconShape.IconsetEntry(fileName: "icon_16x16.png", pixels: 16))
        try expectEqual(entries[1], AppIconShape.IconsetEntry(fileName: "icon_16x16@2x.png", pixels: 32))
        try expectEqual(entries.last!, AppIconShape.IconsetEntry(fileName: "icon_512x512@2x.png", pixels: 1024))
    }
}

@MainActor
func localisationTests() {
    let t = TestRun.shared

    t.run("AppStrings", "picks the first supported preferred language") {
        try expectEqual(AppStrings.preferred(["de-DE", "en-GB"]), .german)
        try expectEqual(AppStrings.preferred(["ja-JP", "fr-CA", "en"]), .french)
        try expectEqual(AppStrings.preferred(["es-419"]), .spanish)
        try expectEqual(AppStrings.preferred(["nl-BE"]), .dutch)
        try expectEqual(AppStrings.preferred(["da"]), .danish)
        try expectEqual(AppStrings.preferred(["en-US", "de"]), .english)
    }
    t.run("AppStrings", "falls back to English") {
        try expectEqual(AppStrings.preferred(["ja-JP", "zh-Hans"]), .english)
        try expectEqual(AppStrings.preferred([]), .english)
    }
    t.run("AppStrings", "has every string in every language") {
        try expectEqual(AppStrings.byLanguage.count, 6)
        for (code, strings) in AppStrings.byLanguage {
            let all = [strings.calendar, strings.previous, strings.next,
                       strings.launchAtLogin, strings.quit, strings.launchAtLoginFailed]
            try expect(all.allSatisfy { !$0.isEmpty }, "\(code) has an empty string")
            try expect(strings.quit.contains("MenuBarCalendar"), "\(code) quit names the app")
            if code != "en" {
                try expect(strings != .english, "\(code) is translated")
            }
        }
    }

    for (identifier, march, firstWeekday) in [("de_DE", "März", "M"), ("fr_FR", "mars", "L"),
                                              ("es_ES", "marzo", "L"), ("nl_NL", "maart", "M"),
                                              ("da_DK", "marts", "M")] {
        t.run("Locale \(identifier)", "names months and weekdays in the calendar's language") {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: identifier)
            calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
            let state = CalendarState(today: Day(year: 2026, month: 3, day: 10))
            let title = CalendarHeader.parts(for: state, calendar: calendar)
            try expectEqual(title.first!.text.lowercased(), march.lowercased())
            let grid = MonthGrid(month: state.month, calendar: calendar)
            try expectEqual(grid.weekdaySymbols.first!.uppercased(), firstWeekday)
            try expectEqual(grid.days.first!, Day(year: 2026, month: 2, day: 23))
            let months = PickerGrid.months(of: 2026, displayed: state.month, today: state.today, calendar: calendar)
            try expectEqual(Set(months.items.map(\.label)).count, 12)
        }
    }
}
