import SwiftUI

struct MeetingDetailView: View {
    @ObservedObject var vm: MeetingsViewModel
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var showingMinutes = false
    @State private var selectedObjectiveId: UUID?

    var body: some View {
        List {
            Section("Detalles") {
                LabeledContent("Título", value: meeting.title)
                if let date = meeting.meetingDate {
                    LabeledContent("Fecha", value: date)
                }
                if let time = meeting.meetingTime {
                    LabeledContent("Hora", value: time)
                }
                if meeting.isFromGoogle {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                        Text("Sincronizado desde Google Calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let participants = meeting.participants, !participants.isEmpty {
                Section("Participantes") {
                    ForEach(participants.components(separatedBy: ","), id: \.self) { p in
                        Label(p.trimmingCharacters(in: .whitespaces), systemImage: "person")
                    }
                }
            }

            if let agenda = meeting.agenda, !agenda.isEmpty {
                Section("Agenda") {
                    Text(agenda)
                        .font(.body)
                }
            }

            Section("Objetivo asociado") {
                Picker("Objetivo", selection: $selectedObjectiveId) {
                    Text("Ninguno").tag(nil as UUID?)
                    ForEach(vm.objectives) { obj in
                        Text(obj.title).tag(obj.id as UUID?)
                    }
                }
                .onChange(of: selectedObjectiveId) { newValue in
                    Task {
                        await vm.setObjective(
                            meetingId: meeting.id,
                            objectiveId: newValue
                        )
                    }
                }
            }

            Section("Minuta") {
                if meeting.minutesProcessedAt != nil {
                    Label("Minuta procesada", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                Button {
                    showingMinutes = true
                } label: {
                    Label("Procesar minuta", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .navigationTitle("Reunión")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMinutes) {
            MinutasView(vm: vm, meetingId: meeting.id)
        }
        .task {
            await vm.fetchObjectives()
            selectedObjectiveId = meeting.objectiveId
        }
    }
}
