import Foundation

extension Date {
    /// "17 mar 2026"
    var shortFormatted: String {
        formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// "17 de marzo de 2026"
    var longFormatted: String {
        formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "es_MX")))
    }

    /// "8:30 AM"
    var timeFormatted: String {
        formatted(.dateTime.hour().minute())
    }

    /// Returns a relative description like "Hoy", "Mañana", "Ayer", or the short date.
    var relativeFormatted: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Hoy" }
        if calendar.isDateInTomorrow(self) { return "Mañana" }
        if calendar.isDateInYesterday(self) { return "Ayer" }
        return shortFormatted
    }
}
