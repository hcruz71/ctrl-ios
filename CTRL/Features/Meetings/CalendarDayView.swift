import SwiftUI

struct CalendarDayView: View {
    @ObservedObject var vm: MeetingsViewModel
    @State private var selectedDate = Date()
    @State private var meetings: [Meeting] = []
    @State private var currentTime = Date()
    @State private var isLoading = false

    private let hourHeight: CGFloat = 60
    private let startHour = 0
    private let endHour = 24
    private let labelWidth: CGFloat = 44

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // HEADER
            header

            Divider()

            // Meetings without time
            let noTimeMeetings = meetings.filter { !isValidTime($0.meetingTime) }
            if !noTimeMeetings.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(noTimeMeetings) { meeting in
                            NavigationLink {
                                MeetingDetailView(vm: vm, meeting: meeting)
                            } label: {
                                noTimeBadge(meeting)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
                .background(Color(.systemGroupedBackground))
                Divider()
            }

            // HOUR GRID
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        // Hour lines
                        hourGrid

                        // Meeting blocks
                        meetingBlocks

                        // Current time indicator
                        if isToday {
                            currentTimeIndicator
                        }
                    }
                    .frame(height: CGFloat(endHour - startHour) * hourHeight)
                }
                .onAppear {
                    scrollToCurrentTime(proxy: proxy)
                }
            }
        }
        .task { await loadMeetings() }
        .onChange(of: selectedDate) { _ in
            Task { await loadMeetings() }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(df.string(from: selectedDate).capitalized)
                    .font(.headline)
                if !isToday {
                    Button("Hoy") {
                        withAnimation { selectedDate = Date() }
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.ctrlPurple)
                }
            }

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Hour Grid

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(alignment: .top, spacing: 0) {
                    Text(hourLabel(hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: labelWidth, alignment: .trailing)
                        .padding(.trailing, 4)
                        .offset(y: -6)

                    VStack(spacing: 0) {
                        Divider()
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
                .id(hour)
            }
        }
    }

    // MARK: - Meeting Layout (overlap distribution)

    private struct MeetingLayout: Identifiable {
        let meeting: Meeting
        let columnIndex: Int
        let totalColumns: Int
        var id: UUID { meeting.id }
    }

    private func parseMinutes(_ timeStr: String) -> Int {
        let parts = timeStr.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]), h >= 0, h < 24,
              let m = Int(parts[1]), m >= 0, m < 60 else { return 0 }
        return h * 60 + m
    }

    private func isValidTime(_ timeStr: String?) -> Bool {
        guard let t = timeStr, !t.isEmpty else { return false }
        let parts = t.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]), h >= 0, h < 24,
              let m = Int(parts[1]), m >= 0, m < 60 else { return false }
        return true
    }

    private func layoutMeetings(_ meetings: [Meeting]) -> [MeetingLayout] {
        let timed = meetings
            .filter { isValidTime($0.meetingTime) }
            .sorted { parseMinutes($0.meetingTime ?? "0") < parseMinutes($1.meetingTime ?? "0") }

        guard !timed.isEmpty else { return [] }

        let defaultDuration = 60 // minutes
        struct Span { let id: UUID; let start: Int; let end: Int }
        let spans = timed.map { m -> Span in
            let s = parseMinutes(m.meetingTime ?? "0")
            return Span(id: m.id, start: s, end: s + defaultDuration)
        }

        // Greedy column assignment
        var columns: [[Span]] = []
        var assignment: [UUID: Int] = [:]

        for span in spans {
            var placed = false
            for (colIdx, col) in columns.enumerated() {
                if let last = col.last, last.end <= span.start {
                    columns[colIdx].append(span)
                    assignment[span.id] = colIdx
                    placed = true
                    break
                }
            }
            if !placed {
                assignment[span.id] = columns.count
                columns.append([span])
            }
        }

        // Build overlap groups to determine totalColumns per meeting
        // A group shares at least one overlapping span chain
        var groupOf: [UUID: Int] = [:]
        var groups: [[UUID]] = []

        for (i, spanA) in spans.enumerated() {
            if groupOf[spanA.id] == nil {
                let gIdx = groups.count
                groups.append([spanA.id])
                groupOf[spanA.id] = gIdx
            }
            let gIdx = groupOf[spanA.id]!
            for j in (i + 1)..<spans.count {
                let spanB = spans[j]
                if spanB.start >= spanA.end { break } // sorted, no more overlaps
                if groupOf[spanB.id] == nil {
                    groups[gIdx].append(spanB.id)
                    groupOf[spanB.id] = gIdx
                }
            }
        }

        // Max columns per group
        var groupMaxCols: [Int: Int] = [:]
        for (gIdx, members) in groups.enumerated() {
            let maxCol = members.compactMap { assignment[$0] }.max() ?? 0
            groupMaxCols[gIdx] = maxCol + 1
        }

        return timed.map { m in
            let col = assignment[m.id] ?? 0
            let gIdx = groupOf[m.id] ?? 0
            let total = groupMaxCols[gIdx] ?? 1
            return MeetingLayout(meeting: m, columnIndex: col, totalColumns: total)
        }
    }

    // MARK: - Meeting Blocks

    private var meetingBlocks: some View {
        let gridWidth = UIScreen.main.bounds.width - 16
        let contentWidth = gridWidth - labelWidth - 4
        let layouts = layoutMeetings(meetings)

        return ForEach(layouts) { layout in
            let colWidth = max(20, contentWidth / CGFloat(max(1, layout.totalColumns)))
            let blockWidth = max(20, colWidth - 4)
            let blockHeight = max(44, hourHeight - 4)
            let xOrigin = labelWidth + 4 + CGFloat(layout.columnIndex) * colWidth + colWidth / 2
            let yPos = max(0, yOffset(for: layout.meeting.meetingTime ?? "00:00")) + blockHeight / 2

            NavigationLink {
                MeetingDetailView(vm: vm, meeting: layout.meeting)
            } label: {
                meetingBlock(layout.meeting, width: blockWidth, height: blockHeight)
            }
            .buttonStyle(.plain)
            .position(x: xOrigin, y: yPos)
        }
    }

    private func meetingBlock(_ meeting: Meeting, width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(meetingColor(meeting))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(meeting.title)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                if let time = meeting.meetingTime {
                    Text(time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let organizer = meeting.organizer {
                    Text(organizer)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            attendanceBadge(meeting)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(width: width, height: height, alignment: .leading)
        .background(meetingColor(meeting).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(meetingColor(meeting).opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        let cal = Calendar.current
        let minutes = cal.component(.hour, from: currentTime) * 60 + cal.component(.minute, from: currentTime)
        let y = CGFloat(minutes) * (hourHeight / 60)

        return HStack(spacing: 0) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .padding(.leading, labelWidth - 4)

            Rectangle()
                .fill(.red)
                .frame(height: 2)
        }
        .offset(y: y - 1)
    }

    // MARK: - Helpers

    private func loadMeetings() async {
        isLoading = true
        meetings = await vm.fetchByDate(selectedDate)
        isLoading = false
    }

    private func yOffset(for timeStr: String) -> CGFloat {
        let parts = timeStr.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return 0 }
        return CGFloat(h * 60 + m) * (hourHeight / 60)
    }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    private func meetingColor(_ meeting: Meeting) -> Color {
        if let obj = meeting.objective, let area = obj.area,
           let areaEnum = ObjectiveArea(rawValue: area) {
            return areaEnum.color
        }
        return Color.ctrlPurple
    }

    @ViewBuilder
    private func attendanceBadge(_ meeting: Meeting) -> some View {
        let status = meeting.attendanceStatus ?? ""
        switch status {
        case "atendida", "asistir":
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case "delegada":
            Image(systemName: "person.fill.badge.plus")
                .foregroundStyle(.blue)
                .font(.caption)
        case "ignorar":
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.gray)
                .font(.caption)
        default:
            EmptyView()
        }
    }

    private func noTimeBadge(_ meeting: Meeting) -> some View {
        Text(meeting.title)
            .font(.caption)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(meetingColor(meeting).opacity(0.12))
            .foregroundStyle(meetingColor(meeting))
            .clipShape(Capsule())
    }

    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let hour = max(0, Calendar.current.component(.hour, from: Date()) - 1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation { proxy.scrollTo(hour, anchor: .top) }
        }
    }
}
