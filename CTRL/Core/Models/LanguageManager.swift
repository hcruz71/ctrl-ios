import Foundation

final class LanguageManager {
    static let shared = LanguageManager()

    private let key = "appLanguage"

    var currentLanguage: String {
        get { UserDefaults.standard.string(forKey: key) ?? "es" }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    var languageLabel: String {
        Self.label(for: currentLanguage)
    }

    static let supportedLanguages: [(code: String, label: String, flag: String)] = [
        ("es", "Espanol", "🇲🇽🇪🇸"),
        ("en", "English", "🇺🇸🇬🇧"),
        ("pt", "Portugues", "🇧🇷🇵🇹"),
        ("fr", "Francais", "🇫🇷"),
        ("de", "Deutsch", "🇩🇪"),
    ]

    static func label(for code: String) -> String {
        supportedLanguages.first { $0.code == code }?.label ?? "Espanol"
    }

    private init() {}
}
