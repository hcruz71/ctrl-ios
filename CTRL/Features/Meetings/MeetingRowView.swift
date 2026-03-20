import SwiftUI

struct MeetingRowView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if meeting.isFromGoogle {
                    Image(systemName: "globe")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                if meeting.objective != nil {
                    Image(systemName: "target")
                        .font(.caption)
                        .foregroundStyle(Color.ctrlTeal)
                }
                if meeting.minutesProcessedAt != nil {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: 12) {
                if let date = meeting.meetingDate {
                    Label(date, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let time = meeting.meetingTime {
                    Label(time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let participants = meeting.participants, !participants.isEmpty {
                Label(participants, systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let agenda = meeting.agenda, !agenda.isEmpty {
                Text(agenda)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
