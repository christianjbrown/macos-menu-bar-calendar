import Foundation
import CalendarCore

/// Writes the app icon as an .iconset folder, ready for `iconutil -c icns`.
public enum AppIconWriter {
    public static func writeIconset(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for entry in AppIconShape.iconsetEntries {
            try AppIconRenderer.pngData(pixels: entry.pixels).write(to: directory.appendingPathComponent(entry.fileName))
        }
    }
}
