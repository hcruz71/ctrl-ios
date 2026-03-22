import SwiftUI

struct MeetingDetailView: View {
    @ObservedObject var vm: MeetingsViewModel
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var showingMinutes = false
    @State private var selectedObjectiveId: UUID?
    @State private var showAllAttendees = false
    @State private var addContactAttendee: MeetingAttendee?

    private var allAttendees: [MeetingAttendee] {
        meeting.attendees ?? []
    }

    private var knownCount: Int {
        allAttendees.filter { att in
            guard let email = att.email?.lowercased() else { return false }
            return vm.attendeeContacts[email] != nil
        }.count
    }

    private var visibleAttendees: [MeetingAttendee] {
        if showAllAttendees || allAttendees.count <= 4 {
            return allAttendees
        }
        // Show organizer + first 3
        let organizer = allAttendees.filter { $0.isOrganizer == true }
        let others = allAttendees.filter { $0.isOrganizer != true }.prefix(3)
        return organizer + others
    }

    var body: some View {
        List {
            Section("Detalles") {
                LabeledContent("Titulo", value: meeting.title)
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

            // Attendees section
            if !allAttendees.isEmpty {
                Section {
                    ForEach(Array(visibleAttendees.enumerated()), id: \.offset) { _, att in
                        attendeeRow(att)
                    }

                    if allAttendees.count > 4 {
                        Button {
                            withAnimation { showAllAttendees.toggle() }
                        } label: {
                            Text(showAllAttendees
                                 ? "Ocultar"
                                 : "Ver todos (\(allAttendees.count) participantes)")
                                .font(.subheadline)
                                .foregroundStyle(Color.ctrlPurple)
                        }
                    }
                } header: {
                    HStack {
                        Text("Participantes (\(allAttendees.count))")
                        Spacer()
                        if knownCount > 0 {
                            Text("\(knownCount) conocidos")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
            } else if let participants = meeting.participants, !participants.isEmpty {
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
                        await vm.setObjective(meetingId: meeting.id, objectiveId: newValue)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Listo") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil)
                }
            }
        }
        .navigationTitle("Reunion")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMinutes) {
            MinutasView(vm: vm, meetingId: meeting.id)
        }
        .sheet(item: $addContactAttendee) { att in
            AddContactFromAttendeeSheet(attendee: att) {
                // Reload contacts after adding
                Task { await vm.matchAttendeesWithContacts(attendees: allAttendees) }
            }
        }
        .task {
            await vm.fetchObjectives()
            selectedObjectiveId = meeting.objectiveId
            await vm.matchAttendeesWithContacts(attendees: allAttendees)
        }
    }

    // MARK: - Attendee Row

    @ViewBuilder
    private func attendeeRow(_ att: MeetingAttendee) -> some View {
        let email = att.email?.lowercased() ?? ""
        let contact = vm.attendeeContacts[email]
        let isKnown = contact != nil

        HStack(spacing: 10) {
            // Avatar
            Circle()
                .fill(avatarColor(att: att, contact: contact).opacity(0.15))
                .frame(width: 34, height: 34)
                .overlay {
                    Text(String((att.name ?? att.email ?? "?").prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(avatarColor(att: att, contact: contact))
                }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(contact?.name ?? att.name ?? att.email ?? "Desconocido")
                        .font(.subheadline)

                    if att.isOrganizer == true {
                        Text("Org")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }

                    if let contact {
                        Text(contact.networkLabel)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(networkColor(contact).opacity(0.1))
                            .foregroundStyle(networkColor(contact))
                            .clipShape(Capsule())
                    } else if !email.isEmpty {
                        Text("Desconocido")
                            .font(.system(size: 9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.1))
                            .foregroundStyle(.gray)
                            .clipShape(Capsule())
                    }
                }

                if let email = att.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Add contact button for unknowns
            if !isKnown && att.email != nil {
                Button {
                    addContactAttendee = att
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundStyle(Color.ctrlPurple)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func avatarColor(att: MeetingAttendee, contact: Contact?) -> Color {
        if att.isOrganizer == true { return .orange }
        if let c = contact { return networkColor(c) }
        return .gray
    }

    private func networkColor(_ contact: Contact) -> Color {
        switch contact.networkType {
        case "operativa":   return .blue
        case "personal":    return .green
        case "estrategica": return .purple
        default:            return .gray
        }
    }
}

// MARK: - Make MeetingAttendee Identifiable for sheet

extension MeetingAttendee: Identifiable {
    var id: String { email ?? UUID().uuidString }
}

// MARK: - Add Contact from Attendee Sheet

private struct AddContactFromAttendeeSheet: View {
    let attendee: MeetingAttendee
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var company: String = ""
    @State private var networkType: String = "operativa"
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Contacto") {
                    TextField("Nombre", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Organizacion") {
                    TextField("Empresa", text: $company)
                }
                Section("Tipo de red") {
                    Picker("Tipo", selection: $networkType) {
                        Text("Operativa").tag("operativa")
                        Text("Personal").tag("personal")
                        Text("Estrategica").tag("estrategica")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationTitle("Agregar contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .onAppear {
                name = attendee.name ?? ""
                email = attendee.email ?? ""
                // Extract company from email domain
                if let domain = attendee.email?.components(separatedBy: "@").last {
                    let parts = domain.components(separatedBy: ".")
                    if let first = parts.first, first != "gmail" && first != "hotmail" && first != "outlook" && first != "yahoo" {
                        company = first.prefix(1).uppercased() + first.dropFirst()
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let body = CreateContactBody(
            name: name,
            email: email.isEmpty ? nil : email,
            company: company.isEmpty ? nil : company,
            networkType: networkType
        )
        do {
            let _: Contact = try await APIClient.shared.request(.contacts, body: body)
            onSave()
            dismiss()
        } catch { }
        isSaving = false
    }
}
