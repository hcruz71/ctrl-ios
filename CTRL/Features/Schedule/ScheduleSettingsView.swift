import SwiftUI

struct ScheduleSettingsView: View {
    @ObservedObject private var lang = LanguageManager.shared
    @State private var workDays: Set<Int> = [1, 2, 3, 4, 5]
    @State private var workStart = Self.dateFromTime("08:00")
    @State private var workEnd = Self.dateFromTime("18:00")
    @State private var personalEnd = Self.dateFromTime("22:00")
    @State private var restMessage = "Es dia de descanso. Disfruta."
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var currentMode: WorkMode = .work
    @State private var showSaved = false
    @State private var saveError: String?

    private let dayLabels: [(Int, String)] = [
        (1, "L"), (2, "M"), (3, "X"), (4, "J"), (5, "V"), (6, "S"), (7, "D"),
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Label(lang.t("schedule.current_mode"), systemImage: currentMode.icon)
                    Spacer()
                    Text(currentMode.label)
                        .fontWeight(.medium)
                        .foregroundStyle(modeColor)
                }
            }

            Section(lang.t("schedule.work_days")) {
                HStack(spacing: 8) {
                    ForEach(dayLabels, id: \.0) { num, label in
                        Button {
                            if workDays.contains(num) {
                                workDays.remove(num)
                            } else {
                                workDays.insert(num)
                            }
                        } label: {
                            Text(label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 36, height: 36)
                                .background(workDays.contains(num) ? Color.ctrlPurple : Color(.systemGray5))
                                .foregroundStyle(workDays.contains(num) ? .white : .primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section(lang.t("schedule.work_hours")) {
                DatePicker(lang.t("schedule.start"), selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker(lang.t("schedule.end"), selection: $workEnd, displayedComponents: .hourAndMinute)
            }

            Section {
                DatePicker(lang.t("schedule.ends_at"), selection: $personalEnd, displayedComponents: .hourAndMinute)
            } header: {
                Text(lang.t("schedule.personal_time"))
            } footer: {
                Text(lang.t("schedule.personal_footer"))
            }

            Section {
                TextField(lang.t("schedule.rest_placeholder"), text: $restMessage)
            } header: {
                Text(lang.t("schedule.rest_message"))
            } footer: {
                Text(lang.t("schedule.rest_footer"))
            }

            Section {
                Button {
                    Task { await saveSchedule() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else if showSaved {
                            Label(lang.t("schedule.saved"), systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        } else {
                            Text(lang.t("schedule.save"))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)

                if let error = saveError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(lang.t("common.done")) {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationTitle(lang.t("schedule.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSchedule()
            await loadMode()
            isLoading = false
        }
    }

    private var modeColor: Color {
        switch currentMode {
        case .work:     return .blue
        case .personal: return .green
        case .rest:     return .gray
        case .vacation: return .orange
        }
    }

    private func loadSchedule() async {
        do {
            let s: UserSchedule = try await APIClient.shared.request(.schedule)
            workDays = Set(s.workDays)
            workStart = Self.dateFromTime(s.workStart)
            workEnd = Self.dateFromTime(s.workEnd)
            personalEnd = Self.dateFromTime(s.personalEnd)
            restMessage = s.restMessage
        } catch { }
    }

    private func loadMode() async {
        do {
            let r: WorkModeResponse = try await APIClient.shared.request(.scheduleMode)
            currentMode = r.mode
        } catch { }
    }

    private func saveSchedule() async {
        isSaving = true
        saveError = nil
        showSaved = false
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"

        struct Body: Encodable {
            let workDays: [Int]
            let workStart: String
            let workEnd: String
            let personalStart: String
            let personalEnd: String
            let restMessage: String
        }

        let body = Body(
            workDays: Array(workDays).sorted(),
            workStart: tf.string(from: workStart),
            workEnd: tf.string(from: workEnd),
            personalStart: tf.string(from: workEnd),
            personalEnd: tf.string(from: personalEnd),
            restMessage: restMessage
        )

        #if DEBUG
        print("[Schedule] Saving: \(Array(workDays).sorted()), \(tf.string(from: workStart))-\(tf.string(from: workEnd))")
        #endif

        do {
            let _: UserSchedule = try await APIClient.shared.request(
                .schedule, method: "PUT", body: body
            )
            showSaved = true
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showSaved = false
            }
        } catch {
            #if DEBUG
            print("[Schedule] Save error: \(error)")
            #endif
            saveError = error.localizedDescription
        }
        await loadMode()
        isSaving = false
    }

    private static func dateFromTime(_ time: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.date(from: time) ?? Date()
    }
}
