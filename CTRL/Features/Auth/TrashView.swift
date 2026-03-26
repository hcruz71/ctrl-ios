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
    @State private var expandedDeleted = true
    @State private var expandedCompleted = true
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

    private var deletedTasks: [CTRLTask] {
        trashTasks.filter { $0.isDeleted == true }
    }
    private var completedTasks: [CTRLTask] {
        trashTasks.filter { $0.done && $0.isDeleted != true }
    }

    private var deletedProjects: [Project] {
        trashProjects.filter { $0.isDeleted == true }
    }
    private var completedProjects: [Project] {
        trashProjects.filter { $0.status == "completado" && $0.isDeleted != true }
    }

    private var deletedObjectives: [Objective] {
        trashObjectives.filter { $0.isDeleted == true }
    }
    private var completedObjectives: [Objective] {
        trashObjectives.filter { $0.status == "completado" && $0.isDeleted != true }
    }

    var totalCount: Int {
        trashTasks.count + trashProjects.count + trashObjectives.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if totalCount > 0 {
                Text("\(totalCount) \(lang.t("trash.title").lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }

            Picker("", selection: $selectedTab) {
                Text(lang.t("trash.tasks")).tag(0)
                Text(lang.t("trash.projects")).tag(1)
                Text(lang.t("trash.objectives")).tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                TabView(selection: $selectedTab) {
                    tasksList.tag(0)
                    projectsList.tag(1)
                    objectivesList.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            Text(lang.t("trash.auto_delete"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 8)
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
            Button(lang.t("action.delete"), role: .destructive) {
                Task { await emptyTrash() }
            }
        } message: {
            Text(lang.t("trash.empty_confirm"))
        }
        .overlay(alignment: .bottom) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
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
                    if !deletedTasks.isEmpty {
                        collapsibleSection(
                            expanded: $expandedDeleted,
                            title: lang.t("trash.deleted"),
                            count: deletedTasks.count,
                            icon: "trash",
                            color: .red
                        ) {
                            ForEach(deletedTasks) { task in
                                trashRow(
                                    title: task.title,
                                    subtitle: formattedDate(task.deletedAt ?? task.updatedAt),
                                    subtitleKey: "trash.deleted_on",
                                    restoreLabel: lang.t("trash.restore"),
                                    restoreIcon: "arrow.uturn.backward",
                                    onRestore: { Task { await restoreTask(task.id) } },
                                    onDelete: { Task { await hardDeleteTask(task.id) } }
                                )
                            }
                        }
                    }
                    if !completedTasks.isEmpty {
                        collapsibleSection(
                            expanded: $expandedCompleted,
                            title: lang.t("trash.completed"),
                            count: completedTasks.count,
                            icon: "checkmark.circle",
                            color: .green
                        ) {
                            ForEach(completedTasks) { task in
                                trashRow(
                                    title: task.title,
                                    subtitle: formattedDate(task.updatedAt),
                                    subtitleKey: "trash.completed_on",
                                    restoreLabel: lang.t("trash.reactivate"),
                                    restoreIcon: "arrow.counterclockwise",
                                    onRestore: { Task { await reactivateTask(task.id) } },
                                    onDelete: { Task { await hardDeleteTask(task.id) } }
                                )
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
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
                        collapsibleSection(
                            expanded: $expandedDeleted,
                            title: lang.t("trash.deleted"),
                            count: deletedProjects.count,
                            icon: "trash",
                            color: .red
                        ) {
                            ForEach(deletedProjects) { project in
                                trashRow(
                                    title: project.name,
                                    subtitle: formattedDate(project.deletedAt ?? project.updatedAt),
                                    subtitleKey: "trash.deleted_on",
                                    restoreLabel: lang.t("trash.restore"),
                                    restoreIcon: "arrow.uturn.backward",
                                    onRestore: { Task { await restoreProject(project.id) } },
                                    onDelete: { Task { await hardDeleteProject(project.id) } }
                                )
                            }
                        }
                    }
                    if !completedProjects.isEmpty {
                        collapsibleSection(
                            expanded: $expandedCompleted,
                            title: lang.t("trash.completed"),
                            count: completedProjects.count,
                            icon: "checkmark.circle",
                            color: .green
                        ) {
                            ForEach(completedProjects) { project in
                                trashRow(
                                    title: project.name,
                                    subtitle: formattedDate(project.updatedAt),
                                    subtitleKey: "trash.completed_on",
                                    restoreLabel: lang.t("trash.reactivate"),
                                    restoreIcon: "arrow.counterclockwise",
                                    onRestore: { Task { await reactivateProject(project.id) } },
                                    onDelete: { Task { await hardDeleteProject(project.id) } }
                                )
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
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
                        collapsibleSection(
                            expanded: $expandedDeleted,
                            title: lang.t("trash.deleted"),
                            count: deletedObjectives.count,
                            icon: "trash",
                            color: .red
                        ) {
                            ForEach(deletedObjectives) { objective in
                                trashRow(
                                    title: objective.title,
                                    subtitle: formattedDate(objective.deletedAt ?? objective.updatedAt),
                                    subtitleKey: "trash.deleted_on",
                                    restoreLabel: lang.t("trash.restore"),
                                    restoreIcon: "arrow.uturn.backward",
                                    onRestore: { Task { await restoreObjective(objective.id) } },
                                    onDelete: { Task { await hardDeleteObjective(objective.id) } }
                                )
                            }
                        }
                    }
                    if !completedObjectives.isEmpty {
                        collapsibleSection(
                            expanded: $expandedCompleted,
                            title: lang.t("trash.completed"),
                            count: completedObjectives.count,
                            icon: "checkmark.circle",
                            color: .green
                        ) {
                            ForEach(completedObjectives) { objective in
                                trashRow(
                                    title: objective.title,
                                    subtitle: formattedDate(objective.updatedAt),
                                    subtitleKey: "trash.completed_on",
                                    restoreLabel: lang.t("trash.reactivate"),
                                    restoreIcon: "arrow.counterclockwise",
                                    onRestore: { Task { await reactivateObjective(objective.id) } },
                                    onDelete: { Task { await hardDeleteObjective(objective.id) } }
                                )
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    // MARK: - Reusable components

    private func collapsibleSection<Content: View>(
        expanded: Binding<Bool>,
        title: String,
        count: Int,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section {
            if expanded.wrappedValue {
                content()
            }
        } header: {
            Button {
                withAnimation { expanded.wrappedValue.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.caption)
                    Text(title)
                        .font(.subheadline.bold())
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.8))
                        .clipShape(Capsule())
                    Spacer()
                    Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func trashRow(
        title: String,
        subtitle: String?,
        subtitleKey: String,
        restoreLabel: String,
        restoreIcon: String,
        onRestore: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
            if let subtitle {
                Text("\(lang.t(subtitleKey)) \(subtitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { onRestore() } label: {
                Label(restoreLabel, systemImage: restoreIcon)
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label(lang.t("action.delete"), systemImage: "trash.fill")
            }
        }
    }

    private func emptyState(_ type: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trash")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("\(type) — \(lang.t("tasks.empty"))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
