import SwiftUI

struct TasksView: View {
    @StateObject private var vm = TasksViewModel()
    @State private var showingAdd = false
    @State private var newTitle = ""
    @State private var newPriority = "media"
    @State private var newProject = ""
    @State private var newDueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedContactIds: Set<UUID> = []
    @State private var showingContactPicker = false

    private let priorities = ["alta", "media", "baja"]

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
                        ForEach(vm.tasks) { task in
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
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchTasks() }
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
            .sheet(isPresented: $showingAdd) {
                addTaskSheet
            }
            .task { await vm.fetchTasks() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Tarea") {
                    TextField("Título", text: $newTitle)
                    Picker("Prioridad", selection: $newPriority) {
                        ForEach(priorities, id: \.self) { Text($0.capitalized) }
                    }
                    TextField("Proyecto", text: $newProject)
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
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"

                        let body = CreateTaskBody(
                            title: newTitle,
                            priority: newPriority,
                            project: newProject.isEmpty ? nil : newProject,
                            dueDate: hasDueDate ? df.string(from: newDueDate) : nil,
                            contactIds: selectedContactIds.isEmpty
                                ? nil
                                : selectedContactIds.map { $0.uuidString }
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newTitle = ""
                            newProject = ""
                            hasDueDate = false
                            selectedContactIds = []
                        }
                    }
                    .disabled(newTitle.isEmpty)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: $selectedContactIds)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    TasksView()
}
