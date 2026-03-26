import SwiftUI

struct TrashView: View {
    @EnvironmentObject var lang: LanguageManager
    let initialTab: String
    @State private var selectedTab: Int
    @State private var trashTasks: [CTRLTask] = []
    @State private var trashProjects: [Project] = []
    @State private var trashObjectives: [Objective] = []
    @State private var isLoading = false
    @State private var showEmptyAlert = false
    @State private var expandedDeletedTasks = true
    @State private var expandedCompletedTasks = true
    @State private var expandedDeletedProjects = true
    @State private var expandedCompletedProjects = true
    @State private var expandedDeletedObjectives = true
    @State private var expandedCompletedObjectives = true
    @State private var toastMessage: String?

    init(initialTab: String = "tasks") {
        self.initialTab = initialTab
        let tab: Int
        switch initialTab {
        case "projects":   tab = 1
        case "objectives": tab = 2
        default:           tab = 0
        }
        _selectedTab = State(initialValue: tab)
    }

    // MARK: - Computed filters

    private var deletedTasks: [CTRLTask] { trashTasks.filter { $0.isDeleted == true } }
    private var completedTasks: [CTRLTask] { trashTasks.filter { $0.done && $0.isDeleted != true } }
    private var deletedProjects: [Project] { trashProjects.filter { $0.isDeleted == true } }
    private var completedProjects: [Project] { trashProjects.filter { $0.status == "completado" && $0.isDeleted != true } }
    private var deletedObjectives: [Objective] { trashObjectives.filter { $0.isDeleted == true } }
    private var completedObjectives: [Objective] { trashObjectives.filter { $0.status == "completado" && $0.isDeleted != true } }

    var totalCount: Int { trashTasks.count + trashProjects.count + trashObjectives.count }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if totalCount > 0 {
                Text("\(totalCount) \(lang.t("trash.title").lowercased())")
                    .font(.caption).foregroundStyle(.secondary).padding(.vertical, 6)
            }

            Picker("", selection: $selectedTab) {
                Text(lang.t("trash.tasks")).tag(0)
                Text(lang.t("trash.projects")).tag(1)
                Text(lang.t("trash.objectives")).tag(2)
            }
            .pickerStyle(.segmented).padding(.horizontal).padding(.bottom, 8)

            if isLoading {
                Spacer(); ProgressView(); Spacer()
            } else {
                TabView(selection: $selectedTab) {
                    tasksList.tag(0)
                    projectsList.tag(1)
                    objectivesList.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            Text(lang.t("trash.auto_delete"))
                .font(.caption2).foregroundStyle(.tertiary).padding(.vertical, 8)
        }
        .navigationTitle(lang.t("trash.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if totalCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { showEmptyAlert = true } label: {
                        Label(lang.t("trash.empty"), systemImage: "trash.slash")
                    }
                }
            }
        }
        .alert(lang.t("trash.empty"), isPresented: $showEmptyAlert) {
            Button(lang.t("action.cancel"), role: .cancel) {}
            Button(lang.t("action.delete"), role: .destructive) { Task { await emptyTrash() } }
        } message: { Text(lang.t("trash.empty_confirm")) }
        .overlay(alignment: .bottom) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.subheadline)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial).clipShape(Capsule()).shadow(radius: 4)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Tasks list

    private var tasksList: some View {
        Group {
            if deletedTasks.isEmpty && completedTasks.isEmpty {
                emptyState(lang.t("trash.tasks"))
            } else {
                List {
                    // Deleted tasks
                    if !deletedTasks.isEmpty {
                        Section {
                            if expandedDeletedTasks {
                                ForEach(deletedTasks) { task in
                                    rowContent(title: task.title, date: task.deletedAt ?? task.updatedAt, dateKey: "trash.deleted_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await restoreTask(task.id) } } label: {
                                                Label(lang.t("trash.restore"), systemImage: "arrow.uturn.backward")
                                            }.tint(.green)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteTask(task.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.deleted"), count: deletedTasks.count, icon: "trash", color: .red, expanded: $expandedDeletedTasks)
                        }
                    }

                    // Completed tasks
                    if !completedTasks.isEmpty {
                        Section {
                            if expandedCompletedTasks {
                                ForEach(completedTasks) { task in
                                    rowContent(title: task.title, date: task.updatedAt, dateKey: "trash.completed_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await reactivateTask(task.id) } } label: {
                                                Label(lang.t("trash.reactivate"), systemImage: "arrow.counterclockwise")
                                            }.tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteTask(task.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.completed"), count: completedTasks.count, icon: "checkmark.circle", color: .green, expanded: $expandedCompletedTasks)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Projects list

    private var projectsList: some View {
        Group {
            if deletedProjects.isEmpty && completedProjects.isEmpty {
                emptyState(lang.t("trash.projects"))
            } else {
                List {
                    if !deletedProjects.isEmpty {
                        Section {
                            if expandedDeletedProjects {
                                ForEach(deletedProjects) { project in
                                    rowContent(title: project.name, date: project.deletedAt ?? project.updatedAt, dateKey: "trash.deleted_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await restoreProject(project.id) } } label: {
                                                Label(lang.t("trash.restore"), systemImage: "arrow.uturn.backward")
                                            }.tint(.green)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteProject(project.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.deleted"), count: deletedProjects.count, icon: "trash", color: .red, expanded: $expandedDeletedProjects)
                        }
                    }

                    if !completedProjects.isEmpty {
                        Section {
                            if expandedCompletedProjects {
                                ForEach(completedProjects) { project in
                                    rowContent(title: project.name, date: project.updatedAt, dateKey: "trash.completed_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await reactivateProject(project.id) } } label: {
                                                Label(lang.t("trash.reactivate"), systemImage: "arrow.counterclockwise")
                                            }.tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteProject(project.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.completed"), count: completedProjects.count, icon: "checkmark.circle", color: .green, expanded: $expandedCompletedProjects)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Objectives list

    private var objectivesList: some View {
        Group {
            if deletedObjectives.isEmpty && completedObjectives.isEmpty {
                emptyState(lang.t("trash.objectives"))
            } else {
                List {
                    if !deletedObjectives.isEmpty {
                        Section {
                            if expandedDeletedObjectives {
                                ForEach(deletedObjectives) { objective in
                                    rowContent(title: objective.title, date: objective.deletedAt ?? objective.updatedAt, dateKey: "trash.deleted_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await restoreObjective(objective.id) } } label: {
                                                Label(lang.t("trash.restore"), systemImage: "arrow.uturn.backward")
                                            }.tint(.green)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteObjective(objective.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.deleted"), count: deletedObjectives.count, icon: "trash", color: .red, expanded: $expandedDeletedObjectives)
                        }
                    }

                    if !completedObjectives.isEmpty {
                        Section {
                            if expandedCompletedObjectives {
                                ForEach(completedObjectives) { objective in
                                    rowContent(title: objective.title, date: objective.updatedAt, dateKey: "trash.completed_on")
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button { Task { await reactivateObjective(objective.id) } } label: {
                                                Label(lang.t("trash.reactivate"), systemImage: "arrow.counterclockwise")
                                            }.tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) { Task { await hardDeleteObjective(objective.id) } } label: {
                                                Label(lang.t("action.delete"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        } header: {
                            collapseHeader(lang.t("trash.completed"), count: completedObjectives.count, icon: "checkmark.circle", color: .green, expanded: $expandedCompletedObjectives)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    // MARK: - Components

    private func rowContent(title: String, date: Date?, dateKey: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            if let d = formattedDate(date) {
                Text("\(lang.t(dateKey)) \(d)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func collapseHeader(_ title: String, count: Int, icon: String, color: Color, expanded: Binding<Bool>) -> some View {
        Button {
            withAnimation { expanded.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color).font(.caption)
                Text(title).font(.subheadline.bold())
                Text("\(count)")
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(color.opacity(0.8)).clipShape(Capsule())
                Spacer()
                Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ type: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trash").font(.system(size: 40)).foregroundStyle(.tertiary)
            Text("\(type) — \(lang.t("tasks.empty"))")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    // MARK: - API calls

    private func loadAll() async {
        isLoading = true
        async let t: [CTRLTask] = (try? APIClient.shared.request(.tasksTrash)) ?? []
        async let p: [Project] = (try? APIClient.shared.request(.projectsTrash)) ?? []
        async let o: [Objective] = (try? APIClient.shared.request(.objectivesTrash)) ?? []
        trashTasks = await t
        trashProjects = await p
        trashObjectives = await o
        isLoading = false
    }

    // Tasks
    private func restoreTask(_ id: UUID) async {
        let _: CTRLTask? = try? await APIClient.shared.request(.taskRestore(id: id), method: "PATCH")
        withAnimation { trashTasks.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func reactivateTask(_ id: UUID) async {
        var body = UpdateTaskBody()
        body.done = false
        body.priorityLevel = "B"
        body.inbox = false
        let _: CTRLTask? = try? await APIClient.shared.request(.task(id: id), method: "PATCH", body: body)
        withAnimation { trashTasks.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func hardDeleteTask(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.taskHardDelete(id: id), method: "DELETE")
        withAnimation { trashTasks.removeAll { $0.id == id } }
    }

    // Projects
    private func restoreProject(_ id: UUID) async {
        let _: Project? = try? await APIClient.shared.request(.projectRestore(id: id), method: "PATCH")
        withAnimation { trashProjects.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func reactivateProject(_ id: UUID) async {
        let body = UpdateProjectBody(status: "activo")
        let _: Project? = try? await APIClient.shared.request(.project(id: id), method: "PATCH", body: body)
        withAnimation { trashProjects.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func hardDeleteProject(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.projectHardDelete(id: id), method: "DELETE")
        withAnimation { trashProjects.removeAll { $0.id == id } }
    }

    // Objectives
    private func restoreObjective(_ id: UUID) async {
        let _: Objective? = try? await APIClient.shared.request(.objectiveRestore(id: id), method: "PATCH")
        withAnimation { trashObjectives.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func reactivateObjective(_ id: UUID) async {
        let body = UpdateObjectiveBody(status: "activo")
        let _: Objective? = try? await APIClient.shared.request(.objective(id: id), method: "PATCH", body: body)
        withAnimation { trashObjectives.removeAll { $0.id == id } }
        showToast("Restaurado correctamente")
    }

    private func hardDeleteObjective(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.objectiveHardDelete(id: id), method: "DELETE")
        withAnimation { trashObjectives.removeAll { $0.id == id } }
    }

    private func emptyTrash() async {
        try? await APIClient.shared.requestVoid(.trashEmpty, method: "DELETE")
        withAnimation {
            trashTasks.removeAll()
            trashProjects.removeAll()
            trashObjectives.removeAll()
        }
    }
}
