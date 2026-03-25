import SwiftUI

struct TasksView: View {
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var vm = TasksViewModel()
    @State private var showingAdd = false
    @State private var expandedA = true
    @State private var expandedB = true
    @State private var expandedC = true
    @State private var expandedDelegated = true
    @State private var expandedInbox = true
    @State private var taskToEdit: CTRLTask?
    @State private var taskToEmail: CTRLTask?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.tasks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.tasks.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: lang.t("tasks.empty"),
                        message: ""
                    )
                } else {
                    List {
                        prioritySection(
                            title: lang.t("tasks.urgentA"),
                            icon: "flame.fill",
                            color: .red,
                            tasks: vm.tasksA,
                            expanded: $expandedA,
                            level: "A"
                        )
                        prioritySection(
                            title: lang.t("tasks.importantB"),
                            icon: "star.fill",
                            color: .orange,
                            tasks: vm.tasksB,
                            expanded: $expandedB,
                            level: "B"
                        )
                        prioritySection(
                            title: lang.t("tasks.pendingC"),
                            icon: "clock.fill",
                            color: .blue,
                            tasks: vm.tasksC,
                            expanded: $expandedC,
                            level: "C"
                        )
                        delegatedSection
                        inboxSection
                    }
                    .listStyle(.sidebar)
                    .refreshable { await vm.fetchAll() }
                }
            }
            .navigationTitle(lang.t("tasks.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                AddTaskSheet(vm: vm)
            }
            .sheet(item: $taskToEdit) { task in
                EditTaskSheet(task: task) {
                    Task { await vm.fetchAll() }
                }
            }
            .sheet(item: $taskToEmail) { task in
                TaskEmailSheet(task: task)
            }
            .task { await vm.fetchAll() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Priority Section

    private static let allLevels: [(key: String, label: String, icon: String, color: Color)] = [
        ("A", "Urgente (A)", "flame.fill", .red),
        ("B", "Importante (B)", "star.fill", .orange),
        ("C", "Pendiente (C)", "clock.fill", .blue),
    ]

    @ViewBuilder
    private func prioritySection(
        title: String,
        icon: String,
        color: Color,
        tasks: [CTRLTask],
        expanded: Binding<Bool>,
        level: String
    ) -> some View {
        Section {
            if expanded.wrappedValue {
                ForEach(tasks) { task in
                    taskRow(task: task, level: level)
                }
                .onMove { from, to in
                    var ids = tasks.map(\.id)
                    ids.move(fromOffsets: from, toOffset: to)
                    Task { await vm.reorder(level: level, ids: ids) }
                }

            }
        } header: {
            sectionHeader(title: title, icon: icon, color: color, tasks: tasks, expanded: expanded, level: level)
        }
    }

    @ViewBuilder
    private func taskRow(task: CTRLTask, level: String) -> some View {
        let otherLevels = Self.allLevels.filter { $0.key != level }
        TaskRowView(task: task, onToggle: {
            Task { await vm.toggleDone(task: task) }
        }, onChangePriority: { newLevel in
            Task { await vm.changePriority(task: task, newLevel: newLevel) }
        })
        .draggable(task.id.uuidString)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task { await vm.delete(id: task.id) }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button { taskToEdit = task } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.blue)
            ForEach(otherLevels, id: \.key) { lvl in
                Button {
                    Task { await vm.changePriority(task: task, newLevel: lvl.key) }
                } label: {
                    Label(lvl.label, systemImage: lvl.icon)
                }
                .tint(lvl.color)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(
        title: String,
        icon: String,
        color: Color,
        tasks: [CTRLTask],
        expanded: Binding<Bool>,
        level: String
    ) -> some View {
        let pendingCount = tasks.filter { !$0.done }.count
        Button {
            withAnimation { expanded.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(pendingCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15), in: Capsule())
                    .foregroundStyle(color)
                Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .dropDestination(for: String.self) { droppedIds, _ in
            guard let taskIdStr = droppedIds.first,
                  let taskId = UUID(uuidString: taskIdStr) else { return false }
            Task { await vm.changePriorityById(taskId, newLevel: level) }
            return true
        } isTargeted: { _ in }
    }

    // MARK: - Delegated Section

    private var delegatedSection: some View {
        Section {
            if expandedDelegated {
                ForEach(vm.delegatedTasks) { task in
                    TaskRowView(task: task, onToggle: {
                        Task { await vm.toggleDone(task: task) }
                    })
                    .swipeActions(edge: .leading) {
                        Button { taskToEdit = task } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                        Button {
                            Task { await vm.recover(task: task) }
                        } label: {
                            Label("Recuperar", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            taskToEmail = task
                        } label: {
                            Label("Correo", systemImage: "envelope")
                        }
                        .tint(.orange)
                        Button(role: .destructive) {
                            Task { await vm.delete(id: task.id) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Menu("Status") {
                            Button { Task { await vm.updateDelegationStatus(task: task, status: "pendiente") } } label: {
                                Label("Pendiente", systemImage: "clock")
                            }
                            Button { Task { await vm.updateDelegationStatus(task: task, status: "en_proceso") } } label: {
                                Label("En proceso", systemImage: "arrow.forward")
                            }
                            Button { Task { await vm.updateDelegationStatus(task: task, status: "completada") } } label: {
                                Label("Completada", systemImage: "checkmark")
                            }
                        }
                        Button {
                            Task { await vm.recover(task: task) }
                        } label: {
                            Label("Recuperar para mi", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
        } header: {
            Button {
                withAnimation { expandedDelegated.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                    Text(lang.t("tasks.delegated").uppercased())
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    if !vm.delegatedTasks.isEmpty {
                        Text("\(vm.delegatedTasks.filter { !$0.done }.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                    Image(systemName: expandedDelegated ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Inbox Section

    private var inboxSection: some View {
        Section {
            if expandedInbox {
                ForEach(vm.inboxTasks) { task in
                    HStack {
                        TaskRowView(task: task) {
                            Task { await vm.toggleDone(task: task) }
                        }
                        Menu {
                            Button {
                                Task { await vm.classify(task: task, level: "A") }
                            } label: {
                                Label("Urgente (A)", systemImage: "flame.fill")
                            }
                            Button {
                                Task { await vm.classify(task: task, level: "B") }
                            } label: {
                                Label("Importante (B)", systemImage: "star.fill")
                            }
                            Button {
                                Task { await vm.classify(task: task, level: "C") }
                            } label: {
                                Label("Pendiente (C)", systemImage: "clock.fill")
                            }
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(Color.ctrlPurple)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button { taskToEdit = task } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await vm.delete(id: task.id) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Button {
                withAnimation { expandedInbox.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tray.fill")
                        .foregroundStyle(.secondary)
                    Text("INBOX")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    if !vm.inboxTasks.isEmpty {
                        Text("\(vm.inboxTasks.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.ctrlPurple.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.ctrlPurple)
                    }
                    Image(systemName: expandedInbox ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Add Task Sheet

private struct AddTaskSheet: View {
    @ObservedObject var vm: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedLevel: String?
    @State private var startDate = Date()
    @State private var hasStartDate = false
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var hasEndDate = false
    @State private var isDelegated = false
    @State private var assignee = ""
    @State private var assigneeContactId: UUID?
    @State private var delegationNotes = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedContactIds: Set<UUID> = []
    @State private var sourceType: String?
    @State private var sourceNotes = ""
    @State private var assigneeEmail = ""
    @State private var assigneePhone = ""
    @State private var saveAsContact = false
    @State private var sourceReferenceId: UUID? = nil

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
                    assigneeEmail: $assigneeEmail,
                    assigneePhone: $assigneePhone,
                    saveAsContact: $saveAsContact,
                    sourceReferenceId: $sourceReferenceId
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
            .navigationTitle(LanguageManager.shared.t("tasks.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LanguageManager.shared.t("action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LanguageManager.shared.t("action.save")) {
                        save()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        Task {
            var finalContactId = assigneeContactId

            // Auto-create contact if requested
            if isDelegated && saveAsContact && !assignee.isEmpty && assigneeContactId == nil {
                let contactBody = CreateContactBody(
                    name: assignee,
                    email: assigneeEmail.isEmpty ? nil : assigneeEmail,
                    phone: assigneePhone.isEmpty ? nil : assigneePhone,
                    networkType: "operativa"
                )
                do {
                    let created: Contact = try await APIClient.shared.request(.contacts, body: contactBody)
                    finalContactId = created.id
                } catch { }
            }

            let body = CreateTaskBody(
                title: title,
                priorityLevel: selectedLevel,
                projectId: selectedProjectId?.uuidString,
                dueDate: hasEndDate ? df.string(from: endDate) : nil,
                startDate: hasStartDate ? df.string(from: startDate) : nil,
                inbox: selectedLevel == nil ? true : false,
                contactIds: selectedContactIds.isEmpty
                    ? nil
                    : selectedContactIds.map { $0.uuidString },
                isDelegated: isDelegated ? true : nil,
                assignee: isDelegated && !assignee.isEmpty ? assignee : nil,
                assigneeContactId: isDelegated ? finalContactId?.uuidString : nil,
                delegationNotes: isDelegated && !delegationNotes.isEmpty ? delegationNotes : nil,
                sourceType: sourceType,
                sourceReferenceId: sourceReferenceId?.uuidString,
                sourceNotes: sourceNotes.isEmpty ? nil : sourceNotes
            )
            await vm.create(body)
            dismiss()
        }
    }
}

#Preview {
    TasksView()
}
