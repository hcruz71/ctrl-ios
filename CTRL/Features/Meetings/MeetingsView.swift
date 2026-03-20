import SwiftUI

struct MeetingsView: View {
    @StateObject private var vm = MeetingsViewModel()
    @State private var showingAdd = false
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newTime = Date()
    @State private var newParticipants = ""
    @State private var newAgenda = ""

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.meetings.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.meetings.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "Sin reuniones",
                        message: "Agenda tu primera reunión."
                    )
                } else {
                    List {
                        ForEach(vm.meetings) { meeting in
                            MeetingRowView(meeting: meeting)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(id: meeting.id) }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchMeetings() }
                }
            }
            .navigationTitle("Reuniones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                addMeetingSheet
            }
            .task { await vm.fetchMeetings() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addMeetingSheet: some View {
        NavigationStack {
            Form {
                Section("Reunión") {
                    TextField("Título", text: $newTitle)
                    DatePicker("Fecha", selection: $newDate, displayedComponents: .date)
                    DatePicker("Hora", selection: $newTime, displayedComponents: .hourAndMinute)
                }
                Section("Detalles") {
                    TextField("Participantes (separados por coma)", text: $newParticipants)
                    TextField("Agenda", text: $newAgenda, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Nueva reunión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"
                        let tf = DateFormatter()
                        tf.dateFormat = "HH:mm"

                        let body = CreateMeetingBody(
                            title: newTitle,
                            meetingDate: df.string(from: newDate),
                            meetingTime: tf.string(from: newTime),
                            participants: newParticipants.isEmpty ? nil : newParticipants,
                            agenda: newAgenda.isEmpty ? nil : newAgenda
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newTitle = ""
                            newParticipants = ""
                            newAgenda = ""
                        }
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MeetingsView()
}
