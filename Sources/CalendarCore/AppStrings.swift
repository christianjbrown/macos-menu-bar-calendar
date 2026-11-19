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
    public let launchAtLoginQuestion: String
    public let launchAtLoginQuestionDetail: String
    public let yes: String
    public let no: String

    public static let english = AppStrings(
        calendar: "Calendar", previous: "Previous", next: "Next",
        launchAtLogin: "Launch at Login", quit: "Quit MenuBarCalendar",
        launchAtLoginFailed: "Could not change Launch at Login",
        launchAtLoginQuestion: "Open MenuBarCalendar when you log in?",
        launchAtLoginQuestionDetail: "You can change this later by right-clicking the calendar in the menu bar.",
        yes: "Yes", no: "No")

    public static let german = AppStrings(
        calendar: "Kalender", previous: "Zurück", next: "Weiter",
        launchAtLogin: "Beim Anmelden öffnen", quit: "MenuBarCalendar beenden",
        launchAtLoginFailed: "„Beim Anmelden öffnen“ konnte nicht geändert werden",
        launchAtLoginQuestion: "MenuBarCalendar beim Anmelden öffnen?",
        launchAtLoginQuestionDetail: "Das lässt sich später per Rechtsklick auf den Kalender in der Menüleiste ändern.",
        yes: "Ja", no: "Nein")

    public static let french = AppStrings(
        calendar: "Calendrier", previous: "Précédent", next: "Suivant",
        launchAtLogin: "Ouvrir à la connexion", quit: "Quitter MenuBarCalendar",
        launchAtLoginFailed: "Impossible de modifier « Ouvrir à la connexion »",
        launchAtLoginQuestion: "Ouvrir MenuBarCalendar à la connexion ?",
        launchAtLoginQuestionDetail: "Vous pourrez modifier ce choix plus tard en cliquant avec le bouton droit sur le calendrier dans la barre des menus.",
        yes: "Oui", no: "Non")

    public static let spanish = AppStrings(
        calendar: "Calendario", previous: "Anterior", next: "Siguiente",
        launchAtLogin: "Abrir al iniciar sesión", quit: "Salir de MenuBarCalendar",
        launchAtLoginFailed: "No se ha podido cambiar «Abrir al iniciar sesión»",
        launchAtLoginQuestion: "¿Abrir MenuBarCalendar al iniciar sesión?",
        launchAtLoginQuestionDetail: "Puedes cambiarlo más tarde haciendo clic con el botón derecho en el calendario de la barra de menús.",
        yes: "Sí", no: "No")

    public static let dutch = AppStrings(
        calendar: "Kalender", previous: "Vorige", next: "Volgende",
        launchAtLogin: "Open bij inloggen", quit: "Stop MenuBarCalendar",
        launchAtLoginFailed: "Kan ‘Open bij inloggen’ niet wijzigen",
        launchAtLoginQuestion: "MenuBarCalendar openen bij inloggen?",
        launchAtLoginQuestionDetail: "Je kunt dit later wijzigen door met de rechtermuisknop op de kalender in de menubalk te klikken.",
        yes: "Ja", no: "Nee")

    public static let danish = AppStrings(
        calendar: "Kalender", previous: "Forrige", next: "Næste",
        launchAtLogin: "Åbn ved login", quit: "Slut MenuBarCalendar",
        launchAtLoginFailed: "Kunne ikke ændre “Åbn ved login”",
        launchAtLoginQuestion: "Åbn MenuBarCalendar ved login?",
        launchAtLoginQuestionDetail: "Du kan ændre det senere ved at højreklikke på kalenderen i menulinjen.",
        yes: "Ja", no: "Nej")

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
