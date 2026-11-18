import Foundation

/// The app's own words. Dates, month and weekday names come from the system calendar's
/// locale instead, so they follow the user's region.
public struct AppStrings: Equatable {
    public let calendar: String
    public let previous: String
    public let next: String
    public let launchAtLogin: String
    public let quit: String
    public let launchAtLoginFailed: String

    public static let english = AppStrings(
        calendar: "Calendar", previous: "Previous", next: "Next",
        launchAtLogin: "Launch at Login", quit: "Quit MenuBarCalendar",
        launchAtLoginFailed: "Could not change Launch at Login")

    public static let german = AppStrings(
        calendar: "Kalender", previous: "Zurück", next: "Weiter",
        launchAtLogin: "Beim Anmelden öffnen", quit: "MenuBarCalendar beenden",
        launchAtLoginFailed: "„Beim Anmelden öffnen“ konnte nicht geändert werden")

    public static let french = AppStrings(
        calendar: "Calendrier", previous: "Précédent", next: "Suivant",
        launchAtLogin: "Ouvrir à la connexion", quit: "Quitter MenuBarCalendar",
        launchAtLoginFailed: "Impossible de modifier « Ouvrir à la connexion »")

    public static let spanish = AppStrings(
        calendar: "Calendario", previous: "Anterior", next: "Siguiente",
        launchAtLogin: "Abrir al iniciar sesión", quit: "Salir de MenuBarCalendar",
        launchAtLoginFailed: "No se ha podido cambiar «Abrir al iniciar sesión»")

    public static let dutch = AppStrings(
        calendar: "Kalender", previous: "Vorige", next: "Volgende",
        launchAtLogin: "Open bij inloggen", quit: "Stop MenuBarCalendar",
        launchAtLoginFailed: "Kan ‘Open bij inloggen’ niet wijzigen")

    public static let danish = AppStrings(
        calendar: "Kalender", previous: "Forrige", next: "Næste",
        launchAtLogin: "Åbn ved login", quit: "Slut MenuBarCalendar",
        launchAtLoginFailed: "Kunne ikke ændre “Åbn ved login”")

    /// Supported languages by ISO 639-1 code. Adding a language is one entry here.
    public static let byLanguage: [String: AppStrings] = [
        "en": english, "de": german, "fr": french, "es": spanish, "nl": dutch, "da": danish,
    ]

    /// Picks the first supported language from the user's preferred languages
    /// (such as "de-DE" or "fr-CA"), or English.
    public static func preferred(_ languages: [String]) -> AppStrings {
        for language in languages {
            if let strings = byLanguage[String(language.prefix(2))] {
                return strings
            }
        }
        return english
    }
}
