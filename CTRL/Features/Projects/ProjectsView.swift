import SwiftUI

struct ProjectsView: View {
    @StateObject private var vm = ProjectsViewModel()
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newPriority = "B"
    @State private var newStartDate = Date()
    @State private var hasStartDate = false
    @State private var newEndDate = Date()
    @State private var hasEndDate = false
    @State private var selectedObjectiveId: UUID?
    @StateObject private var objectivesVM = ObjectivesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.projects.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Sin proyectos")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Crea tu primer proyecto para organizar tareas, reuniones y delegaciones.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(vm.projects) { project in
                            NavigationLink {
                                ProjectDetailView(vm: vm, project: project)
                            } label: {
                                ProjectRowView(project: project)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(id: project.id) }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchProjects() }
                }
            }
            .navigationTitle("Proyectos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                addProjectSheet
            }
            .task { await vm.fetchProjects() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addProjectSheet: some View {
        NavigationStack {
            Form {
                Section("Proyecto") {
                    TextField("Nombre", text: $newName)
                    TextField("Descripcion", text: $newDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Prioridad") {
                    Picker("Prioridad", selection: $newPriority) {
                        Text("A — Urgente").tag("A")
                        Text("B — Importante").tag("B")
                        Text("C — Pendiente").tag("C")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Objetivo vinculado") {
                    Picker("Objetivo", selection: $selectedObjectiveId) {
                        Text("Ninguno").tag(UUID?.none)
                        ForEach(objectivesVM.objectives) { obj in
                            Text(obj.title).tag(Optional(obj.id))
                        }
                    }
                }

                Section("Fechas") {
                    Toggle("Fecha de inicio", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Inicio", selection: $newStartDate, displayedComponents: .date)
                    }
                    Toggle("Fecha de fin", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Fin", selection: $newEndDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Nuevo proyecto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"
                        let body = CreateProjectBody(
                            name: newName,
                            description: newDescription.isEmpty ? nil : newDescription,
                            objectiveId: selectedObjectiveId?.uuidString,
                            priorityLevel: newPriority,
                            startDate: hasStartDate ? df.string(from: newStartDate) : nil,
                            endDate: hasEndDate ? df.string(from: newEndDate) : nil
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newName = ""
                            newDescription = ""
                            selectedObjectiveId = nil
                            hasStartDate = false
                            hasEndDate = false
                        }
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .task { await objectivesVM.fetchObjectives() }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Project Row

private struct ProjectRowView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: project.icon)
                    .foregroundStyle(Color.ctrlPurple)
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(project.priorityLevel)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.15))
                    .foregroundStyle(priorityColor)
                    .clipShape(Capsule())
            }

            if let desc = project.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Progress bar
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.ctrlPurple)
                            .frame(width: geo.size.width * CGFloat(project.taskProgress) / 100)
                    }
                }
                .frame(height: 6)

                Text("\(project.taskProgress)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }

            // Counts
            HStack(spacing: 12) {
                if let t = project.taskCount, t > 0 {
                    Label("\(t) tareas", systemImage: "checkmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let m = project.meetingCount, m > 0 {
                    Label("\(m) reuniones", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let d = project.delegationCount, d > 0 {
                    Label("\(d) delegaciones", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch project.priorityLevel {
        case "A": return .red
        case "B": return .orange
        default:  return .blue
        }
    }
}

#Preview {
    ProjectsView()
}
