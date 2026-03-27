import SwiftUI

struct ProjectsView: View {
    @StateObject private var vm = ProjectsViewModel()
    @State private var showingAdd = false
    @State private var projectToEdit: Project?
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newPriority = "B"
    @State private var newStartDate = Date()
    @State private var hasStartDate = false
    @State private var newEndDate = Date()
    @State private var hasEndDate = false
    @State private var selectedObjectiveId: UUID?
    @StateObject private var objectivesVM = ObjectivesViewModel()
    @State private var showingTrash = false
    @State private var trashBadge = 0
    @State private var filterObjectiveId: UUID? = nil
    @ObservedObject private var lang = LanguageManager.shared

    var filteredProjects: [Project] {
        guard let objectiveId = filterObjectiveId else {
            return vm.projects
        }
        return vm.projects.filter { $0.objectiveId == objectiveId }
    }

    private var objectiveFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    filterObjectiveId = nil
                } label: {
                    Text(lang.t("filter.all"))
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(filterObjectiveId == nil ? Color.ctrlPurple : Color.gray.opacity(0.15))
                        .foregroundColor(filterObjectiveId == nil ? .white : .primary)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)

                ForEach(objectivesVM.objectives) { objective in
                    Button {
                        filterObjectiveId = objective.id
                    } label: {
                        HStack(spacing: 4) {
                            Text(ObjectiveArea(rawValue: objective.area ?? "")?.emoji ?? "🎯")
                                .font(.caption)
                            Text(objective.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(filterObjectiveId == objective.id ? Color.ctrlPurple : Color.gray.opacity(0.15))
                        .foregroundColor(filterObjectiveId == objective.id ? .white : .primary)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

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
                    VStack(spacing: 0) {
                        if !objectivesVM.objectives.isEmpty {
                            objectiveFilterBar
                                .padding(.vertical, 8)
                        }

                        if filteredProjects.isEmpty && filterObjectiveId != nil {
                            VStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text(lang.t("projects.no_objective_projects"))
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Button {
                                    selectedObjectiveId = filterObjectiveId
                                    showingAdd = true
                                } label: {
                                    Label(lang.t("common.create"), systemImage: "plus")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.ctrlPurple)
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredProjects) { project in
                                    NavigationLink {
                                        ProjectDetailView(vm: vm, project: project)
                                    } label: {
                                        ProjectRowView(project: project)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            projectToEdit = project
                                        } label: {
                                            Label("Editar", systemImage: "pencil")
                                        }
                                        .tint(.blue)
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
                }
            }
            .navigationTitle("Proyectos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingTrash = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                            if trashBadge > 0 {
                                Text("\(trashBadge)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(3)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingTrash) {
                NavigationStack {
                    TrashView(initialTab: "projects")
                }
            }
            .sheet(isPresented: $showingAdd) {
                addProjectSheet
            }
            .sheet(item: $projectToEdit) { project in
                EditProjectSheet(vm: vm, project: project) {
                    projectToEdit = nil
                    Task { await vm.fetchProjects() }
                }
            }
            .task {
                await vm.fetchProjects()
                await objectivesVM.fetchObjectives()
                let items: [Project] = (try? await APIClient.shared.request(.projectsTrash)) ?? []
                trashBadge = items.count
            }
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
                            .frame(width: max(0, geo.size.width * min(1, CGFloat(project.taskProgress) / 100)))
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

// MARK: - Edit Project Sheet

private struct EditProjectSheet: View {
    @ObservedObject var vm: ProjectsViewModel
    let project: Project
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var objectivesVM = ObjectivesViewModel()

    @State private var name = ""
    @State private var desc = ""
    @State private var priorityLevel = "B"
    @State private var status = "activo"
    @State private var hasStartDate = false
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var selectedObjectiveId: UUID?
    @State private var isSaving = false

    private let statuses = ["activo", "pausado", "completado", "cancelado"]
    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Proyecto") {
                    TextField("Nombre", text: $name)
                    TextField("Descripcion", text: $desc, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Prioridad") {
                    Picker("Prioridad", selection: $priorityLevel) {
                        Text("A — Urgente").tag("A")
                        Text("B — Importante").tag("B")
                        Text("C — Pendiente").tag("C")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { s in
                            Text(s.capitalized).tag(s)
                        }
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
                        DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                    }
                    Toggle("Fecha de fin", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Fin", selection: $endDate, displayedComponents: .date)
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
            .navigationTitle("Editar proyecto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .task { await objectivesVM.fetchObjectives() }
        .onAppear { loadProject() }
        .presentationDetents([.medium, .large])
    }

    private func loadProject() {
        name = project.name
        desc = project.description ?? ""
        priorityLevel = project.priorityLevel
        status = project.status
        selectedObjectiveId = project.objectiveId
        if let sd = project.startDate, let d = df.date(from: sd) {
            hasStartDate = true
            startDate = d
        }
        if let ed = project.endDate, let d = df.date(from: ed) {
            hasEndDate = true
            endDate = d
        }
    }

    private func save() async {
        isSaving = true
        let body = UpdateProjectBody(
            name: name,
            description: desc.isEmpty ? nil : desc,
            objectiveId: selectedObjectiveId?.uuidString,
            status: status,
            priorityLevel: priorityLevel,
            startDate: hasStartDate ? df.string(from: startDate) : nil,
            endDate: hasEndDate ? df.string(from: endDate) : nil
        )
        await vm.update(id: project.id, body: body)
        onSave()
        dismiss()
    }
}

#Preview {
    ProjectsView()
}
