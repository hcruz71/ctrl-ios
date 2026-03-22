import SwiftUI

struct ScheduleSettingsView: View {
    @State private var workDays: Set<Int> = [1, 2, 3, 4, 5]
    @State private var workStart = Self.dateFromTime("08:00")
    @State private var workEnd = Self.dateFromTime("18:00")
    @State private var personalEnd = Self.dateFromTime("22:00")
    @State private var restMessage = "Es dia de descanso. Disfruta."
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var currentMode: WorkMode = .work

    private let dayNames = [
        (1, "Lu"), (2, "Ma"), (3, "Mi"), (4, "Ju"), (5, "Vi"), (6, "Sa"), (7, "Do"),
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Modo actual", systemImage: currentMode.icon)
                    Spacer()
                    Text(currentMode.label)
                        .fontWeight(.medium)
                        .foregroundStyle(modeColor)
                }
            }

            Section("Dias laborables") {
                HStack(spacing: 8) {
                    ForEach(dayNames, id: \.0) { day in
                        Button {
                            if workDays.contains(day.0) {
                                workDays.remove(day.0)
                            } else {
                                workDays.insert(day.0)
                            }
                        } label: {
                            Text(day.1)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(width: 36, height: 36)
                                .background(workDays.contains(day.0) ? Color.ctrlPurple : Color(.systemGray5))
                                .foregroundStyle(workDays.contains(day.0) ? .white : .primary)
                                .clipShape(Circle())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("Horario laboral") {
                DatePicker("Inicio", selection: $workStart, displayedComponents: .hourAndMinute)
                DatePicker("Fin", selection: $workEnd, displayedComponents: .hourAndMinute)
            }

            Section {
                DatePicker("Termina a las", selection: $personalEnd, displayedComponents: .hourAndMinute)
            } header: {
                Text("Tiempo personal")
            } footer: {
                Text("Despues de esta hora se activa el modo descanso")
            }

            Section {
                TextField("Mensaje cuando es dia libre", text: $restMessage)
            } header: {
                Text("Mensaje de descanso")
            } footer: {
                Text("Se muestra cuando el asistente detecta dia de descanso")
            }

            Section {
                Button {
                    Task { await saveSchedule() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Guardar horario")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .keyboardDismissable()
        .navigationTitle("Horario")
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

        do {
            let _: UserSchedule = try await APIClient.shared.request(
                .schedule, method: "PUT", body: body
            )
        } catch { }
        await loadMode()
        isSaving = false
    }

    private static func dateFromTime(_ time: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.date(from: time) ?? Date()
    }
}
