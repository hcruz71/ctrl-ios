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
    @State private var delegationNotes = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedContactIds: Set<UUID> = []
    @State private var sourceType: String?
    @State private var sourceNotes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                TaskFormView(
                    title: $title,
                    selectedLevel: $selectedLevel,
                    startDate: $startDate,
                    hasStartDate: $hasStartDate,
                    endDate: $endDate,
                    hasEndDate: $hasEndDate,
                    isDelegated: $isDelegated,
                    assignee: $assignee,
                    assigneeContactId: $assigneeContactId,
                    delegationNotes: $delegationNotes,
                    selectedProjectId: $selectedProjectId,
                    selectedContactIds: $selectedContactIds,
                    sourceType: $sourceType,
                    sourceNotes: $sourceNotes,
                    showProjectPicker: false,
                    showContactsPicker: false
                )
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
            assigneeContactId: isDelegated ? assigneeContactId?.uuidString : nil,
            delegationNotes: isDelegated && !delegationNotes.isEmpty ? delegationNotes : nil
        )

        do {
            let _: CTRLTask = try await APIClient.shared.request(.tasks, body: body)
            onSave()
            dismiss()
        } catch { }
        isSaving = false
    }
}
