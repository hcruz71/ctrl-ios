import SwiftUI

struct EditTaskSheet: View {
    let task: CTRLTask
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedLevel: String?
    @State private var startDate = Date()
    @State private var hasStartDate = false
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var isDelegated = false
    @State private var assignee = ""
    @State private var assigneeContactId: UUID?
    @State private var delegationNotes = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedContactIds: Set<UUID> = []
    @State private var isSaving = false
    @State private var didLoad = false

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

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
                    selectedContactIds: $selectedContactIds
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
            .navigationTitle("Editar tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
        .onAppear { loadTask() }
        .presentationDetents([.medium, .large])
    }

    private func loadTask() {
        guard !didLoad else { return }
        didLoad = true
        title = task.title
        selectedLevel = task.priorityLevel
        selectedProjectId = task.projectId
        isDelegated = task.isDelegated ?? false
        assignee = task.assignee ?? ""
        assigneeContactId = task.assigneeContactId
        delegationNotes = task.delegationNotes ?? ""

        if let s = task.startDate, let d = df.date(from: s) {
            hasStartDate = true
            startDate = d
        }
        if let e = task.dueDate, let d = df.date(from: e) {
            hasEndDate = true
            endDate = d
        }

        if let contacts = task.contacts {
            selectedContactIds = Set(contacts.map(\.id))
        }
    }

    private func save() async {
        isSaving = true

        let body = UpdateTaskBody(
            title: title,
            priorityLevel: selectedLevel,
            projectId: selectedProjectId?.uuidString,
            dueDate: hasEndDate ? df.string(from: endDate) : nil,
            startDate: hasStartDate ? df.string(from: startDate) : nil,
            inbox: selectedLevel == nil ? true : false,
            contactIds: selectedContactIds.isEmpty
                ? nil
                : selectedContactIds.map { $0.uuidString },
            isDelegated: isDelegated ? true : false,
            assignee: isDelegated && !assignee.isEmpty ? assignee : nil,
            assigneeContactId: isDelegated ? assigneeContactId?.uuidString : nil,
            delegationNotes: isDelegated && !delegationNotes.isEmpty ? delegationNotes : nil
        )

        do {
            let _: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            onSave()
            dismiss()
        } catch { }
        isSaving = false
    }
}
