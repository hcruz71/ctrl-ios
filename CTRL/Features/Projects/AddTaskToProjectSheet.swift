import SwiftUI

struct AddTaskToProjectSheet: View {
    let projectId: UUID
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedLevel: String? = "B"
    @State private var startDate = Date()
    @State private var hasStartDate = true
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hasEndDate = true
    @State private var isDelegated = false
    @State private var assignee = ""
    @State private var assigneeContactId: UUID?
    @State private var showingContactPicker = false
    @State private var isSaving = false

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
        NavigationStack {
            Form {
                Section("Tarea") {
                    TextField("Titulo", text: $title)
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
                }

                Section("Fechas") {
                    Toggle("Fecha inicio", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                    }
                    Toggle("Fecha fin", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Fin", selection: $endDate, in: startDate..., displayedComponents: .date)
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
                            showingContactPicker = true
                        } label: {
                            HStack {
                                Text("Contacto")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(assigneeContactId != nil ? "Seleccionado" : "Ninguno")
                                    .foregroundStyle(.secondary)
                            }
                        }
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
            .navigationTitle("Nueva tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: Binding(
                    get: { assigneeContactId.map { [$0] } ?? [] },
                    set: { ids in assigneeContactId = ids.first }
                ), singleSelection: true)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() async {
        isSaving = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let body = CreateTaskBody(
            title: title,
            priorityLevel: selectedLevel,
            projectId: projectId.uuidString,
            dueDate: hasEndDate ? df.string(from: endDate) : nil,
            startDate: hasStartDate ? df.string(from: startDate) : nil,
            inbox: false,
            isDelegated: isDelegated ? true : nil,
            assignee: isDelegated && !assignee.isEmpty ? assignee : nil,
            assigneeContactId: isDelegated ? assigneeContactId?.uuidString : nil
        )

        do {
            let _: CTRLTask = try await APIClient.shared.request(.tasks, body: body)
            onSave()
            dismiss()
        } catch { }
        isSaving = false
    }
}
