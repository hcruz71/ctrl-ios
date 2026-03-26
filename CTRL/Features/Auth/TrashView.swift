import SwiftUI

struct TrashView: View {
    @EnvironmentObject var lang: LanguageManager
    let initialTab: String
    @State private var selectedTab: Int
    @State private var deletedTasks: [CTRLTask] = []
    @State private var deletedProjects: [Project] = []
    @State private var deletedObjectives: [Objective] = []
    @State private var isLoading = false
    @State private var showEmptyAlert = false

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

    var totalCount: Int {
        deletedTasks.count + deletedProjects.count + deletedObjectives.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header count
            if totalCount > 0 {
                Text("\(totalCount) \(lang.t("trash.title").lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }

            // Segmented picker
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

            // Auto-delete notice
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
                    Button(role: .destructive) {
                        showEmptyAlert = true
                    } label: {
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
        .task { await loadAll() }
    }

    // MARK: - Lists

    private var tasksList: some View {
        Group {
            if deletedTasks.isEmpty {
                emptyState(lang.t("trash.tasks"))
            } else {
                List {
                    ForEach(deletedTasks) { task in
                        trashRow(
                            title: task.title,
                            subtitle: formattedDate(task.updatedAt),
                            onRestore: { Task { await restoreTask(task.id) } },
                            onDelete: { Task { await hardDeleteTask(task.id) } }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var projectsList: some View {
        Group {
            if deletedProjects.isEmpty {
                emptyState(lang.t("trash.projects"))
            } else {
                List {
                    ForEach(deletedProjects) { project in
                        trashRow(
                            title: project.name,
                            subtitle: formattedDate(project.updatedAt),
                            onRestore: { Task { await restoreProject(project.id) } },
                            onDelete: { Task { await hardDeleteProject(project.id) } }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var objectivesList: some View {
        Group {
            if deletedObjectives.isEmpty {
                emptyState(lang.t("trash.objectives"))
            } else {
                List {
                    ForEach(deletedObjectives) { objective in
                        trashRow(
                            title: objective.title,
                            subtitle: formattedDate(objective.updatedAt),
                            onRestore: { Task { await restoreObjective(objective.id) } },
                            onDelete: { Task { await hardDeleteObjective(objective.id) } }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Components

    private func trashRow(
        title: String,
        subtitle: String?,
        onRestore: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
            if let subtitle {
                Text("\(lang.t("trash.deleted_on")) \(subtitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button { onRestore() } label: {
                Label(lang.t("trash.restore"), systemImage: "arrow.uturn.backward")
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

    // MARK: - API calls

    private func loadAll() async {
        isLoading = true
        async let t: [CTRLTask] = (try? APIClient.shared.request(.tasksTrash)) ?? []
        async let p: [Project] = (try? APIClient.shared.request(.projectsTrash)) ?? []
        async let o: [Objective] = (try? APIClient.shared.request(.objectivesTrash)) ?? []
        deletedTasks = await t
        deletedProjects = await p
        deletedObjectives = await o
        isLoading = false
    }

    private func restoreTask(_ id: UUID) async {
        let _: CTRLTask? = try? await APIClient.shared.request(.taskRestore(id: id), method: "PATCH")
        await loadAll()
    }

    private func hardDeleteTask(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.taskHardDelete(id: id), method: "DELETE")
        await loadAll()
    }

    private func restoreProject(_ id: UUID) async {
        let _: Project? = try? await APIClient.shared.request(.projectRestore(id: id), method: "PATCH")
        await loadAll()
    }

    private func hardDeleteProject(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.projectHardDelete(id: id), method: "DELETE")
        await loadAll()
    }

    private func restoreObjective(_ id: UUID) async {
        let _: Objective? = try? await APIClient.shared.request(.objectiveRestore(id: id), method: "PATCH")
        await loadAll()
    }

    private func hardDeleteObjective(_ id: UUID) async {
        try? await APIClient.shared.requestVoid(.objectiveHardDelete(id: id), method: "DELETE")
        await loadAll()
    }

    private func emptyTrash() async {
        try? await APIClient.shared.requestVoid(.trashEmpty, method: "DELETE")
        await loadAll()
    }
}
