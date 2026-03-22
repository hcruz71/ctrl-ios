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
                        Button {
                            Task { await vm.recover(task: task) }
                        } label: {
                            Label("Recuperar", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
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
                    Text("DELEGADAS")
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
    @State private var newDueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedContactIds: Set<UUID> = []
    @State private var showingContactPicker = false
    @State private var selectedProjectId: UUID?
    @State private var showingProjectPicker = false
    @State private var isDelegated = false
    @State private var assignee = ""
    @State private var assigneeContactId: UUID?
    @State private var showingDelegateContactPicker = false
    @State private var delegationNotes = ""

    private let levels: [(label: String, value: String, color: Color, icon: String)] = [
        ("A", "A", .red, "flame.fill"),
        ("B", "B", .orange, "star.fill"),
        ("C", "C", .blue, "clock.fill"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarea") {
                    TextField("Título", text: $title)
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
                                .padding(.vertical, 12)
                                .background(
                                    selectedLevel == level.value
                                        ? level.color.opacity(0.15)
                                        : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedLevel == level.value ? level.color : .clear,
                                            lineWidth: 2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(
                                selectedLevel == level.value ? level.color : .secondary
                            )
                        }
                    }
                    .padding(.vertical, 4)

                    if selectedLevel == nil {
                        Label("Sin prioridad = va al Inbox", systemImage: "tray")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Fecha límite") {
                    Toggle("Agregar fecha", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Fecha", selection: $newDueDate, displayedComponents: .date)
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
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: $selectedContactIds)
            }
            .sheet(isPresented: $showingProjectPicker) {
                ProjectPickerView(selectedProjectId: $selectedProjectId)
            }
            .sheet(isPresented: $showingDelegateContactPicker) {
                ContactPickerView(selectedIds: Binding(
                    get: { assigneeContactId.map { [$0] } ?? [] },
                    set: { ids in assigneeContactId = ids.first }
                ), singleSelection: true)
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let body = CreateTaskBody(
            title: title,
            priorityLevel: selectedLevel,
            projectId: selectedProjectId?.uuidString,
            dueDate: hasDueDate ? df.string(from: newDueDate) : nil,
            inbox: selectedLevel == nil ? true : false,
            contactIds: selectedContactIds.isEmpty
                ? nil
                : selectedContactIds.map { $0.uuidString },
            isDelegated: isDelegated ? true : nil,
            assignee: isDelegated && !assignee.isEmpty ? assignee : nil,
            assigneeContactId: isDelegated ? assigneeContactId?.uuidString : nil,
            delegationNotes: isDelegated && !delegationNotes.isEmpty ? delegationNotes : nil
        )
        Task {
            await vm.create(body)
            dismiss()
        }
    }
}

#Preview {
    TasksView()
}
