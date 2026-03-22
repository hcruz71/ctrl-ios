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

    var showProjectPicker: Bool = true
    var showContactsPicker: Bool = true

    @State private var showingProjectPicker = false
    @State private var showingContactPicker = false
    @State private var showingDelegateContactPicker = false

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
                TextField("Nombre del responsable", text: $assignee)
                Button {
                    showingDelegateContactPicker = true
                } label: {
                    HStack {
                        Text("Contacto responsable")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(assigneeContactId != nil ? "Seleccionado" : "Ninguno")
                            .foregroundStyle(.secondary)
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
                    set: { ids in assigneeContactId = ids.first }
                ), singleSelection: true)
            }
    }
}
