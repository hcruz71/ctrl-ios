import SwiftUI

struct WatchMeetingsView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if connectivity.meetings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Sin reuniones hoy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    // Next meeting highlight
                    if let next = connectivity.nextMeeting {
                        Section {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Proxima")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Text(next.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                if let time = next.meetingTime {
                                    Text(time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // All meetings
                    Section {
                        ForEach(connectivity.meetings) { meeting in
                            HStack(spacing: 8) {
                                if let time = meeting.meetingTime {
                                    Text(time)
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40)
                                }
                                Text(meeting.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Reuniones")
        .onAppear {
            connectivity.requestMeetings()
        }
    }
}
