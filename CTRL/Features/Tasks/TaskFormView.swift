import SwiftUI

/// Reusable task creation form used by AddTaskSheet and AddTaskToProjectSheet.
struct TaskFormView: View {
    @Binding var title: String
    @Binding var selectedLevel: String?
    @Binding var startDate: Date
    @Binding var hasStartDate: Bool
    @Binding var endDate: Date
    @Binding var hasEndDate: Bool
    @Binding var isDelegated: Bool
    @Binding var assignee: String
    @Binding var assigneeContactId: UUID?
    @Binding var delegationNotes: String
    @Binding var selectedProjectId: UUID?
    @Binding var selectedContactIds: Set<UUID>
    @Binding var sourceType: String?
    @Binding var sourceNotes: String

    var showProjectPicker: Bool = true
    var showContactsPicker: Bool = true

    // Optional bindings — callers that don't pass them get the old UI
    var assigneeEmail: Binding<String>? = nil
    var assigneePhone: Binding<String>? = nil
    var saveAsContact: Binding<Bool>? = nil
    var sourceReferenceId: Binding<UUID?>? = nil

    @State private var showingProjectPicker = false
    @State private var showingContactPicker = false
    @State private var showingDelegateContactPicker = false
    @State private var delegateContacts: [Contact] = []

    private enum DelegateMode: Int { case contact, manual }
    @State private var delegateMode: DelegateMode = .contact
    @State private var todayMeetings: [Meeting] = []
    @State private var selectedMeeting: Meeting? = nil

    private let levels: [(label: String, value: String, color: Color, icon: String)] = [
        ("A", "A", .red, "flame.fill"),
        ("B", "B", .orange, "star.fill"),
        ("C", "C", .blue, "clock.fill"),
    ]

    private var durationText: String? {
        guard hasStartDate, hasEndDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let d = max(1, days)
        if d == 1 { return "1 dia" }
        if d < 7 { return "\(d) dias" }
        if d < 30 { return "\(d / 7) semanas" }
        return "\(d / 30) meses"
    }

    var body: some View {
        Section("Tarea") {
            TextField("Titulo", text: $title)
            if showProjectPicker {
                Button {
                    showingProjectPicker = true
                } label: {
                    HStack {
                        Text("Proyecto")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedProjectId != nil ? "Seleccionado" : "Ninguno")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        Section("Prioridad") {
            HStack(spacing: 12) {
                ForEach(levels, id: \.value) { level in
                    Button {
                        withAnimation {
                            selectedLevel = selectedLevel == level.value ? nil : level.value
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: level.icon)
                                .font(.title3)
                            Text(level.label)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedLevel == level.value
                                ? level.color.opacity(0.15)
                                : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedLevel == level.value ? level.color : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedLevel == level.value ? level.color : .secondary)
                }
            }
            .padding(.vertical, 4)

            if selectedLevel == nil {
                Label("Sin prioridad = va al Inbox", systemImage: "tray")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        Section("Fechas") {
            Toggle("Fecha inicio", isOn: $hasStartDate)
            if hasStartDate {
                DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
            }
            Toggle("Fecha fin", isOn: $hasEndDate)
            if hasEndDate {
                DatePicker("Fin", selection: $endDate, in: hasStartDate ? startDate... : Date.distantPast..., displayedComponents: .date)
            }
            if let dur = durationText {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Duracion: \(dur)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }

        Section("Delegacion") {
            Toggle("Delegar a alguien", isOn: $isDelegated)
            if isDelegated {
                // Mode picker — only when manual delegation is available
                if assigneeEmail != nil {
                    Picker("", selection: $delegateMode) {
                        Text(LanguageManager.shared.t("task.delegate_option_contact"))
                            .tag(DelegateMode.contact)
                        Text(LanguageManager.shared.t("task.delegate_option_manual"))
                            .tag(DelegateMode.manual)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                if delegateMode == .contact || assigneeEmail == nil {
                    // Contact picker (existing flow)
                    Button {
                        showingDelegateContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.blue)
                            if let cId = assigneeContactId,
                               let contact = delegateContacts.first(where: { $0.id == cId }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    if let email = contact.email, !email.isEmpty {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                Text(LanguageManager.shared.t("task.select_contact"))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if assigneeContactId == nil && assigneeEmail == nil {
                        TextField("O escribe el nombre", text: $assignee)
                    }
                } else {
                    // Manual delegation
                    TextField(LanguageManager.shared.t("task.assignee"), text: $assignee)
                    if let emailBinding = assigneeEmail {
                        TextField("Email (opcional)", text: emailBinding)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    if let phoneBinding = assigneePhone {
                        TextField("Telefono (opcional)", text: phoneBinding)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    if let saveBinding = saveAsContact {
                        Toggle(LanguageManager.shared.t("task.save_as_contact"), isOn: saveBinding)
                    }
                }

                TextField("Notas de delegacion...", text: $delegationNotes, axis: .vertical)
                    .lineLimit(2...4)
            }
        }

        if showContactsPicker {
            Section("Contactos") {
                Button {
                    showingContactPicker = true
                } label: {
                    HStack {
                        Text("Asociar contactos")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedContactIds.isEmpty
                             ? "Ninguno"
                             : "\(selectedContactIds.count) seleccionados")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        // Source tracking
        Section(LanguageManager.shared.t("source.origin")) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(sourceTypes, id: \.self) { type in
                    Button {
                        withAnimation { sourceType = sourceType == type ? nil : type }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sourceIconFor(type))
                                .font(.caption)
                            Text(LanguageManager.shared.t("source.\(type)"))
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(sourceType == type ? Color.ctrlPurple.opacity(0.2) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(sourceType == type ? Color.ctrlPurple : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(sourceType == type ? Color.ctrlPurple : .primary)
                }
            }

            // Meeting picker when source is "reunion"
            if sourceType == "reunion", sourceReferenceId != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LanguageManager.shared.t("task.from_meeting"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if todayMeetings.isEmpty {
                        Text(LanguageManager.shared.t("task.no_meetings_today"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(todayMeetings) { meeting in
                            Button {
                                selectedMeeting = meeting
                                sourceNotes = meeting.title
                                sourceReferenceId?.wrappedValue = meeting.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(meeting.title)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        if let time = meeting.meetingTime {
                                            Text(time)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedMeeting?.id == meeting.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.ctrlPurple)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Known participants with matching contacts
                    if let meeting = selectedMeeting,
                       let attendees = meeting.attendees, !attendees.isEmpty {
                        let known = attendees.compactMap { att -> Contact? in
                            guard let email = att.email?.lowercased() else { return nil }
                            return delegateContacts.first { $0.email?.lowercased() == email }
                        }
                        if !known.isEmpty {
                            Text(LanguageManager.shared.t("task.known_participants"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(known) { contact in
                                Button {
                                    assigneeContactId = contact.id
                                    assignee = contact.name
                                    isDelegated = true
                                    delegateMode = .contact
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundStyle(Color.ctrlPurple)
                                        Text(contact.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .font(.caption)
                                            .foregroundStyle(Color.ctrlPurple)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            if sourceType != nil {
                TextField(LanguageManager.shared.t("source.notes_placeholder"), text: $sourceNotes, axis: .vertical)
                    .lineLimit(2...3)
            }
        }

        // Hidden sheets — triggered by buttons above
        Color.clear.frame(height: 0)
            .sheet(isPresented: $showingProjectPicker) {
                ProjectPickerView(selectedProjectId: $selectedProjectId)
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: $selectedContactIds)
            }
            .sheet(isPresented: $showingDelegateContactPicker) {
                ContactPickerView(selectedIds: Binding(
                    get: { assigneeContactId.map { [$0] } ?? [] },
                    set: { ids in
                        assigneeContactId = ids.first
                        // Auto-fill assignee name from loaded contacts
                        if let id = ids.first,
                           let contact = delegateContacts.first(where: { $0.id == id }) {
                            assignee = contact.name
                        }
                    }
                ), singleSelection: true)
            }
            .task {
                // Load contacts for name lookup
                if delegateContacts.isEmpty {
                    do {
                        delegateContacts = try await APIClient.shared.request(.contacts)
                    } catch { }
                }
            }
            .onChange(of: sourceType) { type in
                if type == "reunion" && todayMeetings.isEmpty && sourceReferenceId != nil {
                    Task {
                        do { todayMeetings = try await APIClient.shared.request(.meetingsToday) } catch { }
                    }
                }
                if type != "reunion" {
                    selectedMeeting = nil
                    sourceReferenceId?.wrappedValue = nil
                }
            }
            .onChange(of: delegateMode) { mode in
                if mode == .manual {
                    assigneeContactId = nil
                    assignee = ""
                } else {
                    assigneeEmail?.wrappedValue = ""
                    assigneePhone?.wrappedValue = ""
                    saveAsContact?.wrappedValue = false
                }
            }
    }

    private let sourceTypes = [
        "reunion", "correo", "llamada", "mensaje",
        "decision_propia", "solicitud", "seguimiento", "otro",
    ]

    private func sourceIconFor(_ type: String) -> String {
        switch type {
        case "reunion":         return "calendar"
        case "correo":          return "envelope"
        case "llamada":         return "phone"
        case "mensaje":         return "message"
        case "decision_propia": return "person.fill"
        case "solicitud":       return "person.badge.plus"
        case "seguimiento":     return "arrow.triangle.2.circlepath"
        default:                return "questionmark.circle"
        }
    }
}
