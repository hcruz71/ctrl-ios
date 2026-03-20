import SwiftUI

struct TasksView: View {
    @StateObject private var vm = TasksViewModel()
    @State private var showingAdd = false
    @State private var expandedA = true
    @State private var expandedB = true
    @State private var expandedC = true
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
                        title: "Sin tareas",
                        message: "Crea tu primera tarea pendiente."
                    )
                } else {
                    List {
                        prioritySection(
                            title: "URGENTES (A)",
                            icon: "flame.fill",
                            color: .red,
                            tasks: vm.tasksA,
                            expanded: $expandedA,
                            level: "A"
                        )
                        prioritySection(
                            title: "IMPORTANTES (B)",
                            icon: "star.fill",
                            color: .orange,
                            tasks: vm.tasksB,
                            expanded: $expandedB,
                            level: "B"
                        )
                        prioritySection(
                            title: "PENDIENTES (C)",
                            icon: "clock.fill",
                            color: .blue,
                            tasks: vm.tasksC,
                            expanded: $expandedC,
                            level: "C"
                        )
                        inboxSection
                    }
                    .listStyle(.sidebar)
                    .refreshable { await vm.fetchAll() }
                }
            }
            .navigationTitle("Tareas")
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
                    TaskRowView(task: task) {
                        Task { await vm.toggleDone(task: task) }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await vm.delete(id: task.id) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
                .onMove { from, to in
                    var ids = tasks.map(\.id)
                    ids.move(fromOffsets: from, toOffset: to)
                    Task { await vm.reorder(level: level, ids: ids) }
                }
            }
        } header: {
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
                    Text("\(tasks.filter { !$0.done }.count)")
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
    @State private var project = ""
    @State private var newDueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedContactIds: Set<UUID> = []
    @State private var showingContactPicker = false

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
                    TextField("Proyecto", text: $project)
                }

                Section("Prioridad Franklin Covey") {
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
            .navigationTitle("Nueva tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        save()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: $selectedContactIds)
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
            project: project.isEmpty ? nil : project,
            dueDate: hasDueDate ? df.string(from: newDueDate) : nil,
            inbox: selectedLevel == nil ? true : false,
            contactIds: selectedContactIds.isEmpty
                ? nil
                : selectedContactIds.map { $0.uuidString }
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
