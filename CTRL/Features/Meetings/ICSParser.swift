import Foundation

struct ICSEvent: Identifiable {
    let id = UUID()
    var title: String
    var date: String       // yyyy-MM-dd
    var time: String?      // HH:mm
    var participants: String?
    var agenda: String?
    var isAllDay: Bool
    var isRecurring: Bool

    var dateForSorting: Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: date)
    }

    /// Month-year grouping key
    var monthKey: String {
        guard date.count >= 7 else { return date }
        return String(date.prefix(7))
    }

    var monthLabel: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        guard let d = df.date(from: monthKey) else { return monthKey }
        df.dateFormat = "MMMM yyyy"
        df.locale = Locale(identifier: "es-MX")
        return df.string(from: d).capitalized
    }
}

enum ICSDateFilter: String, CaseIterable, Identifiable {
    case futureOnly = "Solo eventos futuros"
    case threeMonths = "3 meses atras + futuros"
    case oneYear = "1 ano atras + futuros"
    case all = "Todo el archivo"

    var id: String { rawValue }

    var cutoffDate: Date? {
        let cal = Calendar.current
        switch self {
        case .futureOnly:
            return cal.startOfDay(for: Date())
        case .threeMonths:
            return cal.date(byAdding: .month, value: -3, to: Date())
        case .oneYear:
            return cal.date(byAdding: .year, value: -1, to: Date())
        case .all:
            return nil
        }
    }
}

/// Parses iCalendar (.ics) files into ICSEvent structs.
/// Handles TZID dates, UTC (Z) dates, all-day dates, escaped characters,
/// and line continuations (RFC 5545 folding).
actor ICSParser {

    struct ParseOptions {
        var dateFilter: ICSDateFilter = .futureOnly
        var keyword: String? = nil
        var excludeAllDay: Bool = false
        var excludePastRecurring: Bool = true
        var maxEvents: Int = 500
    }

    func parse(data: Data, options: ParseOptions) -> [ICSEvent] {
        guard let raw = String(data: data, encoding: .utf8) else { return [] }

        // Unfold RFC 5545 line continuations: CRLF + whitespace → join
        let unfolded = raw
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n")

        let lines = unfolded.components(separatedBy: "\n")

        var events: [ICSEvent] = []
        var inEvent = false
        var props: [String: String] = [:]
        let cutoff = options.dateFilter.cutoffDate
        let keywordLower = options.keyword?.lowercased()
        let today = Calendar.current.startOfDay(for: Date())

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                props = [:]
                continue
            }

            if trimmed == "END:VEVENT" {
                inEvent = false
                if let event = buildEvent(from: props, cutoff: cutoff, keyword: keywordLower,
                                          excludeAllDay: options.excludeAllDay,
                                          excludePastRecurring: options.excludePastRecurring,
                                          today: today) {
                    events.append(event)
                    if events.count >= options.maxEvents {
                        break
                    }
                }
                continue
            }

            if inEvent {
                // Parse "KEY;PARAMS:VALUE" or "KEY:VALUE"
                if let colonIdx = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[trimmed.startIndex..<colonIdx])
                    let value = String(trimmed[trimmed.index(after: colonIdx)...])

                    // Normalize key — strip parameters for lookup
                    let baseKey = keyPart.components(separatedBy: ";").first ?? keyPart

                    // For DTSTART/DTEND, keep the full key to preserve TZID info
                    if baseKey == "DTSTART" || baseKey == "DTEND" {
                        props[baseKey] = value
                        props[baseKey + "_RAW"] = keyPart
                    } else {
                        props[baseKey] = value
                    }
                }
            }
        }

        return events.sorted { ($0.dateForSorting ?? .distantPast) < ($1.dateForSorting ?? .distantPast) }
    }

    private func buildEvent(
        from props: [String: String],
        cutoff: Date?,
        keyword: String?,
        excludeAllDay: Bool,
        excludePastRecurring: Bool,
        today: Date
    ) -> ICSEvent? {
        guard let summary = props["SUMMARY"] else { return nil }
        let title = unescapeICS(summary)

        guard let dtstart = props["DTSTART"] else { return nil }

        let isAllDay = dtstart.count == 8 // YYYYMMDD with no time
        let isRecurring = props["RRULE"] != nil

        let (date, time) = parseDTStart(dtstart)
        guard let date else { return nil }

        // Apply filters
        if excludeAllDay && isAllDay { return nil }

        if let cutoff {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let eventDate = df.date(from: date), eventDate < cutoff {
                return nil
            }
        }

        if excludePastRecurring && isRecurring {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let eventDate = df.date(from: date), eventDate < today {
                return nil
            }
        }

        if let keyword, !keyword.isEmpty {
            if !title.lowercased().contains(keyword) {
                return nil
            }
        }

        let attendees = parseAttendees(props)
        let description = props["DESCRIPTION"].map { unescapeICS($0) }

        return ICSEvent(
            title: title,
            date: date,
            time: isAllDay ? nil : time,
            participants: attendees,
            agenda: description,
            isAllDay: isAllDay,
            isRecurring: isRecurring
        )
    }

    /// Parses DTSTART value into (date, time) strings.
    /// Handles: 20250320T143000Z, 20250320T143000, 20250320
    private func parseDTStart(_ value: String) -> (String?, String?) {
        let clean = value.trimmingCharacters(in: .whitespaces)

        if clean.count >= 8 {
            let year = String(clean.prefix(4))
            let month = String(clean.dropFirst(4).prefix(2))
            let day = String(clean.dropFirst(6).prefix(2))
            let date = "\(year)-\(month)-\(day)"

            if clean.count >= 15 {
                // Has time component: YYYYMMDDTHHmmss
                let timeStr = String(clean.dropFirst(9).prefix(4))
                if timeStr.count == 4 {
                    let hour = String(timeStr.prefix(2))
                    let minute = String(timeStr.suffix(2))
                    return (date, "\(hour):\(minute)")
                }
            }
            return (date, nil)
        }
        return (nil, nil)
    }

    private func parseAttendees(_ props: [String: String]) -> String? {
        // Attendees may have multiple entries but we stored only unique keys.
        // In practice, ATTENDEE lines get overwritten. For a basic parser,
        // just use ORGANIZER if available.
        let organizer = props["ORGANIZER"]
            .map { unescapeICS($0) }
            .flatMap { extractEmail($0) }

        return organizer
    }

    private func extractEmail(_ value: String) -> String? {
        // ATTENDEE values often contain "mailto:email@example.com"
        if let range = value.range(of: "mailto:", options: .caseInsensitive) {
            return String(value[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        if value.contains("@") { return value }
        return nil
    }

    private func unescapeICS(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
