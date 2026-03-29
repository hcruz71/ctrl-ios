import SwiftUI
import UserNotifications

struct NotificationPreferencesView: View {
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var pushManager = PushManager.shared

    @State private var prefs = NotificationPreferences.defaults
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false

    private let upcomingHoursOptions = [1, 2, 4, 24]
    private let inboxHoursOptions = [4, 8, 24]
    private let delegationDaysOptions = [1, 2, 3, 7]

    var body: some View {
        Form {
            // MARK: - Permission status
            statusSection

            if pushManager.permissionStatus == .authorized {
                // MARK: - Master toggle
                Section {
                    Toggle(lang.t("notif.enabled"), isOn: $prefs.enabled)
                        .onChange(of: prefs.enabled) { _ in save() }
                }

                if prefs.enabled {
                    // MARK: - Tasks
                    Section(lang.t("notif.section_tasks")) {
                        Toggle(lang.t("notif.tasks_overdue"), isOn: $prefs.tasksOverdue)
                            .onChange(of: prefs.tasksOverdue) { _ in save() }

                        Toggle(lang.t("notif.tasks_upcoming"), isOn: $prefs.tasksUpcoming)
                            .onChange(of: prefs.tasksUpcoming) { _ in save() }

                        if prefs.tasksUpcoming {
                            Picker(lang.t("notif.anticipation"), selection: $prefs.tasksUpcomingHours) {
                                ForEach(upcomingHoursOptions, id: \.self) { h in
                                    Text(h == 24 ? lang.t("notif.1day") : "\(h)h").tag(h)
                                }
                            }
                            .onChange(of: prefs.tasksUpcomingHours) { _ in save() }
                        }

                        Toggle(lang.t("notif.inbox_reminder"), isOn: $prefs.inboxReminder)
                            .onChange(of: prefs.inboxReminder) { _ in save() }

                        if prefs.inboxReminder {
                            Picker(lang.t("notif.after"), selection: $prefs.inboxReminderHours) {
                                ForEach(inboxHoursOptions, id: \.self) { h in
                                    Text("\(h)h").tag(h)
                                }
                            }
                            .onChange(of: prefs.inboxReminderHours) { _ in save() }
                        }
                    }

                    // MARK: - Delegations
                    Section(lang.t("notif.section_delegations")) {
                        Toggle(lang.t("notif.delegations_overdue"), isOn: $prefs.delegationsOverdue)
                            .onChange(of: prefs.delegationsOverdue) { _ in save() }

                        if prefs.delegationsOverdue {
                            Picker(lang.t("notif.after"), selection: $prefs.delegationsOverdueDays) {
                                ForEach(delegationDaysOptions, id: \.self) { d in
                                    Text(d == 1 ? "1 \(lang.t("notif.day"))" :
                                         d == 7 ? "1 \(lang.t("notif.week"))" :
                                         "\(d) \(lang.t("notif.days"))").tag(d)
                                }
                            }
                            .onChange(of: prefs.delegationsOverdueDays) { _ in save() }
                        }
                    }

                    // MARK: - Meetings
                    Section(lang.t("notif.section_meetings")) {
                        Toggle(lang.t("notif.meetings_upcoming"), isOn: $prefs.meetingsUpcoming)
                            .onChange(of: prefs.meetingsUpcoming) { _ in save() }
                    }

                    // MARK: - Summaries
                    Section(lang.t("notif.section_summaries")) {
                        Toggle(lang.t("notif.morning_summary"), isOn: $prefs.morningSummary)
                            .onChange(of: prefs.morningSummary) { _ in save() }

                        if prefs.morningSummary {
                            DatePicker(
                                lang.t("notif.time"),
                                selection: Binding(
                                    get: { dateFromTime(prefs.morningSummaryTime) },
                                    set: { prefs.morningSummaryTime = formatTime($0); save() }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }

                        Toggle(lang.t("notif.weekly_review"), isOn: $prefs.weeklyReview)
                            .onChange(of: prefs.weeklyReview) { _ in save() }

                        if prefs.weeklyReview {
                            DatePicker(
                                lang.t("notif.time"),
                                selection: Binding(
                                    get: { dateFromTime(prefs.weeklyReviewTime) },
                                    set: { prefs.weeklyReviewTime = formatTime($0); save() }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(lang.t("notif.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await pushManager.refreshPermissionStatus()
            await loadPrefs()
        }
        .overlay(alignment: .bottom) {
            if showSaved {
                Text(lang.t("notif.saved"))
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: showSaved)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section {
            HStack {
                Label(lang.t("notif.status"), systemImage: "bell.fill")
                Spacer()
                switch pushManager.permissionStatus {
                case .authorized:
                    Text(lang.t("notif.status_active"))
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                case .denied:
                    Text(lang.t("notif.status_denied"))
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                default:
                    Text(lang.t("notif.status_pending"))
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }

            if pushManager.permissionStatus == .notDetermined {
                Button {
                    Task { await pushManager.requestPermissionAndRegister() }
                } label: {
                    Label(lang.t("notif.activate"), systemImage: "bell.badge")
                }
            } else if pushManager.permissionStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(lang.t("notif.open_settings"), systemImage: "gear")
                }
            }
        }
    }

    // MARK: - Actions

    private func loadPrefs() async {
        do {
            prefs = try await APIClient.shared.request(.pushPreferences)
        } catch {
            prefs = .defaults
        }
        isLoading = false
    }

    private func save() {
        guard !isSaving else { return }
        Task { await savePrefs() }
    }

    private func savePrefs() async {
        isSaving = true
        do {
            prefs = try await APIClient.shared.request(.pushPreferences, method: "PUT", body: prefs)
            showSaved = true
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showSaved = false
            }
        } catch {}
        isSaving = false
    }

    // MARK: - Time helpers

    private func dateFromTime(_ time: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        if let d = df.date(from: time) { return d }
        df.dateFormat = "HH:mm"
        return df.date(from: time) ?? Date()
    }

    private func formatTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}
