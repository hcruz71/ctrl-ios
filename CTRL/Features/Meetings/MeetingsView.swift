import SwiftUI

struct MeetingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var vm = MeetingsViewModel()
    @State private var showingAdd = false
    @State private var showingICSImport = false
    @State private var showingProductivity = false
    @State private var showingDeletePast = false
    @State private var isSyncing = false
    @State private var selectedTab = 0
    @State private var deletedCount = 0

    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newTime = Date()
    @State private var newParticipants = ""
    @State private var newAgenda = ""

    private var currentMeetings: [Meeting] {
        switch selectedTab {
        case 0:  return vm.todayMeetings
        case 1:  return vm.upcomingMeetings
        default: return vm.meetings
        }
    }

    private var todayWithObjective: Int {
        vm.todayMeetings.filter { $0.objectiveId != nil }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Vista", selection: $selectedTab) {
                    Text(lang.t("meetings.today")).tag(0)
                    Text(lang.t("meetings.upcoming")).tag(1)
                    Text(lang.t("meetings.all")).tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Header counters for "Hoy" tab
                if selectedTab == 0 && !vm.todayMeetings.isEmpty {
                    HStack {
                        Text("\(vm.todayMeetings.count) \(lang.t("meetings.countToday"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("|")
                            .foregroundStyle(.quaternary)
                        Text("\(todayWithObjective) \(lang.t("meetings.withObj"))")
                            .font(.caption)
                            .foregroundStyle(todayWithObjective > 0 ? .green : .orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }

                // Content
                if vm.isLoading && currentMeetings.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if currentMeetings.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(lang.t("meetings.empty"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(currentMeetings) { meeting in
                            NavigationLink {
                                MeetingDetailView(vm: vm, meeting: meeting)
                            } label: {
                                MeetingRowWithObjective(meeting: meeting)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(id: meeting.id) }
                                } label: {
                                    Label(lang.t("action.delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await refreshCurrentTab() }
                }
            }
            .navigationTitle(lang.t("meetings.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Productivity dashboard
                        Button {
                            showingProductivity = true
                        } label: {
                            Image(systemName: "chart.bar")
                        }

                        // Sync / Import menu
                        Menu {
                            Button {
                                Task {
                                    isSyncing = true
                                    struct R: Codable { let created: Int; let updated: Int }
                                    let _: R? = try? await APIClient.shared.request(.googleCalendarSync)
                                    await refreshCurrentTab()
                                    isSyncing = false
                                }
                            } label: {
                                Label("Sincronizar Google Calendar", systemImage: "arrow.triangle.2.circlepath")
                            }
                            Button {
                                showingICSImport = true
                            } label: {
                                Label("Importar archivo .ics", systemImage: "doc.badge.plus")
                            }
                            Divider()
                            Button(role: .destructive) {
                                showingDeletePast = true
                            } label: {
                                Label("Limpiar reuniones pasadas", systemImage: "trash.circle")
                            }
                        } label: {
                            if isSyncing {
                                ProgressView()
                            } else {
                                Image(systemName: "ellipsis.circle")
                            }
                        }

                        Button { showingAdd = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) { addMeetingSheet }
            .sheet(isPresented: $showingICSImport) { ICSImportView(vm: vm) }
            .sheet(isPresented: $showingProductivity) { ProductivityDashboardView(vm: vm) }
            .alert("Limpiar reuniones pasadas", isPresented: $showingDeletePast) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    Task {
                        deletedCount = await vm.deletePast()
                    }
                }
            } message: {
                Text("Se eliminaran todas las reuniones anteriores a hoy. Esta accion no se puede deshacer.")
            }
            .onChange(of: selectedTab) { _ in
                Task { await refreshCurrentTab() }
            }
            .task {
                await vm.fetchToday()
                await vm.fetchUpcoming()
                await vm.fetchMeetings()
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private func refreshCurrentTab() async {
        switch selectedTab {
        case 0:  await vm.fetchToday()
        case 1:  await vm.fetchUpcoming()
        default: await vm.fetchMeetings()
        }
    }

    private var addMeetingSheet: some View {
        NavigationStack {
            Form {
                Section("Reunion") {
                    TextField("Titulo", text: $newTitle)
                    DatePicker("Fecha", selection: $newDate, displayedComponents: .date)
                    DatePicker("Hora", selection: $newTime, displayedComponents: .hourAndMinute)
                }
                Section("Detalles") {
                    TextField("Participantes (separados por coma)", text: $newParticipants)
                    TextField("Agenda", text: $newAgenda, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .keyboardDismissable()
            .navigationTitle(lang.t("meetings.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.t("action.cancel")) { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.t("action.save")) {
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

// MARK: - Meeting row with objective badge

private struct MeetingRowWithObjective: View {
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
            }

            HStack(spacing: 8) {
                if let time = meeting.meetingTime {
                    Label(time, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let date = meeting.meetingDate {
                    Label(date, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Objective badge
            if let obj = meeting.objective {
                Text(obj.title)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else if meeting.objectiveId == nil {
                Text(LanguageManager.shared.t("meetings.noObjective"))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    MeetingsView()
}
