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
            let noTimeMeetings = meetings.filter { $0.meetingTime == nil || $0.meetingTime?.isEmpty == true }
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

    // MARK: - Meeting Blocks

    private var meetingBlocks: some View {
        ForEach(meetings.filter { $0.meetingTime != nil && !($0.meetingTime?.isEmpty ?? true) }) { meeting in
            NavigationLink {
                MeetingDetailView(vm: vm, meeting: meeting)
            } label: {
                meetingBlock(meeting)
            }
            .buttonStyle(.plain)
            .position(
                x: labelWidth + 4 + (UIScreen.main.bounds.width - labelWidth - 4 - 16) / 2,
                y: yOffset(for: meeting.meetingTime ?? "00:00") + max(44, hourHeight) / 2
            )
        }
    }

    private func meetingBlock(_ meeting: Meeting) -> some View {
        let blockWidth = UIScreen.main.bounds.width - labelWidth - 4 - 16
        let blockHeight = max(hourHeight - 4, 44)

        return HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(meetingColor(meeting))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
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

            Spacer()

            attendanceBadge(meeting)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: blockWidth, height: blockHeight, alignment: .leading)
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
