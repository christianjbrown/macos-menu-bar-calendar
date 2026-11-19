// Writes the app icon's .iconset folder to the path given. build.sh turns it into AppIcon.icns.
import Foundation
import MenuBarCalendarKit

try AppIconWriter.writeIconset(to: URL(fileURLWithPath: CommandLine.arguments[1]))
