import Foundation

struct ICSAttendee: Codable {
    var name: String?
    var email: String?
    var isOrganizer: Bool
}

struct ICSEvent: Identifiable {
    let id = UUID()
    var title: String
    var date: String       // yyyy-MM-dd
    var time: String?      // HH:mm
    var participants: String?
    var agenda: String?
    var isAllDay: Bool
    var isRecurring: Bool
    var attendees: [ICSAttendee]
    var organizer: String?

    var dateForSorting: Date? {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: date)
    }

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

        // Unfold RFC 5545 line continuations
        let unfolded = raw
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\r\n", with: "\n")

        let lines = unfolded.components(separatedBy: "\n")

        var events: [ICSEvent] = []
        var inEvent = false
        var props: [String: String] = [:]
        var attendeeLines: [String] = []
        var organizerLine: String?
        var eventLineBuffer: [String] = []
        var debugEventCount = 0
        let cutoff = options.dateFilter.cutoffDate
        let keywordLower = options.keyword?.lowercased()
        let today = Calendar.current.startOfDay(for: Date())

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                props = [:]
                attendeeLines = []
                organizerLine = nil
                eventLineBuffer = []
                continue
            }

            if trimmed == "END:VEVENT" {
                inEvent = false
                debugEventCount += 1

                // DEBUG: print raw lines of first 3 events
                if debugEventCount <= 3 {
                    let summary = props["SUMMARY"] ?? "(no title)"
                    print("[ICSParser] === EVENT #\(debugEventCount): \(summary) ===")
                    print("[ICSParser] ORGANIZER line: \(organizerLine ?? "(none)")")
                    print("[ICSParser] ATTENDEE lines (\(attendeeLines.count)):")
                    for (i, att) in attendeeLines.enumerated() {
                        print("[ICSParser]   [\(i)] \(att)")
                    }
                    print("[ICSParser] First 20 raw lines of VEVENT:")
                    for (i, rawLine) in eventLineBuffer.prefix(20).enumerated() {
                        print("[ICSParser]   \(i): \(rawLine)")
                    }
                    print("[ICSParser] === END EVENT #\(debugEventCount) ===")
                }
                if let event = buildEvent(
                    from: props,
                    attendeeLines: attendeeLines,
                    organizerLine: organizerLine,
                    cutoff: cutoff,
                    keyword: keywordLower,
                    excludeAllDay: options.excludeAllDay,
                    excludePastRecurring: options.excludePastRecurring,
                    today: today
                ) {
                    events.append(event)
                    if events.count >= options.maxEvents { break }
                }
                continue
            }

            if inEvent {
                eventLineBuffer.append(trimmed)

                // Accumulate ATTENDEE lines (there can be many per event)
                if trimmed.hasPrefix("ATTENDEE") {
                    attendeeLines.append(trimmed)
                    continue
                }

                // Capture ORGANIZER line
                if trimmed.hasPrefix("ORGANIZER") {
                    organizerLine = trimmed
                    continue
                }

                // Other properties
                if let colonIdx = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[trimmed.startIndex..<colonIdx])
                    let value = String(trimmed[trimmed.index(after: colonIdx)...])
                    let baseKey = keyPart.components(separatedBy: ";").first ?? keyPart

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
        attendeeLines: [String],
        organizerLine: String?,
        cutoff: Date?,
        keyword: String?,
        excludeAllDay: Bool,
        excludePastRecurring: Bool,
        today: Date
    ) -> ICSEvent? {
        guard let summary = props["SUMMARY"] else { return nil }
        let title = unescapeICS(summary)

        guard let dtstart = props["DTSTART"] else { return nil }

        let isAllDay = dtstart.count == 8
        let isRecurring = props["RRULE"] != nil

        let rawKey = props["DTSTART_RAW"] ?? ""
        let (date, time) = parseDTStart(dtstart, rawKey: rawKey)
        guard let date else { return nil }

        // Apply filters
        if excludeAllDay && isAllDay { return nil }

        if let cutoff {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let eventDate = df.date(from: date), eventDate < cutoff { return nil }
        }

        if excludePastRecurring && isRecurring {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let eventDate = df.date(from: date), eventDate < today { return nil }
        }

        if let keyword, !keyword.isEmpty {
            if !title.lowercased().contains(keyword) { return nil }
        }

        // Parse organizer
        var organizerAttendee: ICSAttendee?
        var organizerName: String?
        if let orgLine = organizerLine {
            let parsed = parseAttendeetLine(orgLine)
            organizerAttendee = ICSAttendee(
                name: parsed.name,
                email: parsed.email,
                isOrganizer: true
            )
            organizerName = parsed.name ?? parsed.email
        }

        // Parse attendees
        var parsedAttendees: [ICSAttendee] = []
        if let org = organizerAttendee {
            parsedAttendees.append(org)
        }
        for line in attendeeLines {
            let parsed = parseAttendeetLine(line)
            // Skip if same as organizer
            if let orgEmail = organizerAttendee?.email,
               let attEmail = parsed.email,
               orgEmail.lowercased() == attEmail.lowercased() {
                continue
            }
            parsedAttendees.append(ICSAttendee(
                name: parsed.name,
                email: parsed.email,
                isOrganizer: false
            ))
        }

        // Build participants string for backward compat
        let participantsStr = parsedAttendees
            .map { $0.name ?? $0.email ?? "Desconocido" }
            .joined(separator: ", ")

        let description = props["DESCRIPTION"].map { unescapeICS($0) }

        return ICSEvent(
            title: title,
            date: date,
            time: isAllDay ? nil : time,
            participants: participantsStr.isEmpty ? nil : participantsStr,
            agenda: description,
            isAllDay: isAllDay,
            isRecurring: isRecurring,
            attendees: parsedAttendees,
            organizer: organizerName
        )
    }

    /// Parses an ATTENDEE or ORGANIZER line to extract CN and mailto.
    /// Example: ATTENDEE;CN=Juan Garcia;ROLE=REQ-PARTICIPANT:mailto:juan@empresa.com
    private func parseAttendeetLine(_ line: String) -> (name: String?, email: String?) {
        var name: String?
        var email: String?

        // Extract CN= value
        if let cnRange = line.range(of: "CN=", options: .caseInsensitive) {
            let afterCN = String(line[cnRange.upperBound...])
            // CN value ends at ; or :
            if let endIdx = afterCN.firstIndex(where: { $0 == ";" || $0 == ":" }) {
                name = String(afterCN[afterCN.startIndex..<endIdx])
            } else {
                name = afterCN
            }
            // Remove surrounding quotes if present
            name = name?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }

        // Extract mailto: value
        if let mailtoRange = line.range(of: "mailto:", options: .caseInsensitive) {
            let afterMailto = String(line[mailtoRange.upperBound...])
            email = afterMailto.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Unescape
        name = name.map { unescapeICS($0) }

        return (name, email)
    }

    private func parseDTStart(_ value: String, rawKey: String = "") -> (String?, String?) {
        let clean = value.trimmingCharacters(in: .whitespaces)
        guard clean.count >= 8 else { return (nil, nil) }

        // All-day event (YYYYMMDD only)
        if clean.count == 8 {
            let year = String(clean.prefix(4))
            let month = String(clean.dropFirst(4).prefix(2))
            let day = String(clean.dropFirst(6).prefix(2))
            return ("\(year)-\(month)-\(day)", nil)
        }

        // DateTime with time component (YYYYMMDDTHHmmss or YYYYMMDDTHHmmssZ)
        guard clean.count >= 15 else {
            let year = String(clean.prefix(4))
            let month = String(clean.dropFirst(4).prefix(2))
            let day = String(clean.dropFirst(6).prefix(2))
            return ("\(year)-\(month)-\(day)", nil)
        }

        let isUTC = clean.hasSuffix("Z")

        // Check if TZID is specified in the key (e.g., DTSTART;TZID=America/Mexico_City)
        var sourceTZ: TimeZone = .current
        if let tzRange = rawKey.range(of: "TZID=", options: .caseInsensitive) {
            let tzName = String(rawKey[tzRange.upperBound...])
                .components(separatedBy: ";").first ?? ""
            if let tz = TimeZone(identifier: tzName) {
                sourceTZ = tz
            }
        } else if isUTC {
            sourceTZ = TimeZone(identifier: "UTC")!
        }

        // Parse components
        let year = String(clean.prefix(4))
        let month = String(clean.dropFirst(4).prefix(2))
        let day = String(clean.dropFirst(6).prefix(2))
        let hour = String(clean.dropFirst(9).prefix(2))
        let minute = String(clean.dropFirst(11).prefix(2))

        // If already in local timezone and not UTC, return directly
        if !isUTC && sourceTZ == .current {
            return ("\(year)-\(month)-\(day)", "\(hour):\(minute)")
        }

        // Convert to local timezone
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd'T'HHmmss"
        df.timeZone = sourceTZ
        let dateStr = String(clean.prefix(15)) // Strip trailing Z
        guard let date = df.date(from: dateStr) else {
            return ("\(year)-\(month)-\(day)", "\(hour):\(minute)")
        }

        let outDate = DateFormatter()
        outDate.dateFormat = "yyyy-MM-dd"
        outDate.timeZone = .current

        let outTime = DateFormatter()
        outTime.dateFormat = "HH:mm"
        outTime.timeZone = .current

        return (outDate.string(from: date), outTime.string(from: date))
    }

    private func unescapeICS(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
