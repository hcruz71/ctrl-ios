import Foundation

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [CTRLTask] = []
    @Published var todayTasks: [CTRLTask] = []
    @Published var inboxTasks: [CTRLTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed sections

    var ownTasks: [CTRLTask] { todayTasks.filter { $0.isDelegated != true } }
    var delegatedTasks: [CTRLTask] { todayTasks.filter { $0.isDelegated == true } }

    var tasksA: [CTRLTask] { ownTasks.filter { $0.priorityLevel == "A" } }
    var tasksB: [CTRLTask] { ownTasks.filter { $0.priorityLevel == "B" } }
    var tasksC: [CTRLTask] { ownTasks.filter { $0.priorityLevel == "C" } }

    var completedACount: Int { tasksA.filter(\.done).count }
    var totalACount: Int { tasksA.count }

    // MARK: - Fetch

    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let t: [CTRLTask] = APIClient.shared.request(.tasksToday)
            async let i: [CTRLTask] = APIClient.shared.request(.tasksInbox)
            let (today, inbox) = try await (t, i)
            todayTasks = today
            inboxTasks = inbox
            tasks = today + inbox
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchTasks() async {
        await fetchAll()
    }

    // MARK: - Create

    func create(_ body: CreateTaskBody) async {
        do {
            let created: CTRLTask = try await APIClient.shared.request(.tasks, body: body)
            if created.inbox == true {
                inboxTasks.insert(created, at: 0)
            } else {
                todayTasks.append(created)
            }
            tasks = todayTasks + inboxTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Toggle done

    func toggleDone(task: CTRLTask) async {
        do {
            let body = UpdateTaskBody(done: !task.done)
            let _: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            withAnimation(.easeOut(duration: 0.3)) {
                todayTasks.removeAll { $0.id == task.id }
                inboxTasks.removeAll { $0.id == task.id }
                tasks = todayTasks + inboxTasks
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Classify (move from inbox to a priority level)

    func classify(task: CTRLTask, level: String) async {
        do {
            let body = UpdateTaskBody(priorityLevel: level, inbox: false)
            let updated: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            inboxTasks.removeAll { $0.id == task.id }
            todayTasks.append(updated)
            tasks = todayTasks + inboxTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Change Priority (move between A/B/C)

    func changePriority(task: CTRLTask, newLevel: String) async {
        guard task.priorityLevel != newLevel else { return }
        do {
            let body = UpdateTaskBody(priorityLevel: newLevel, inbox: false)
            let updated: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            todayTasks.removeAll { $0.id == task.id }
            inboxTasks.removeAll { $0.id == task.id }
            todayTasks.append(updated)
            tasks = todayTasks + inboxTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePriorityById(_ taskId: UUID, newLevel: String) async {
        if let task = todayTasks.first(where: { $0.id == taskId })
            ?? inboxTasks.first(where: { $0.id == taskId }) {
            await changePriority(task: task, newLevel: newLevel)
        }
    }

    // MARK: - Reorder

    func reorder(level: String, ids: [UUID]) async {
        let body = ReorderTasksBody(
            priorityLevel: level,
            orderedIds: ids.map(\.uuidString)
        )
        do {
            try await APIClient.shared.requestVoid(.tasksReorder, method: "POST", body: body)
            await fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.task(id: id))
            todayTasks.removeAll { $0.id == id }
            inboxTasks.removeAll { $0.id == id }
            tasks = todayTasks + inboxTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delegation

    func delegate(task: CTRLTask, assignee: String, contactId: UUID?) async {
        do {
            let body = UpdateTaskBody(
                isDelegated: true,
                assignee: assignee,
                assigneeContactId: contactId?.uuidString,
                delegationStatus: "pendiente"
            )
            let updated: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            replaceTask(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recover(task: CTRLTask) async {
        do {
            let body = UpdateTaskBody(
                isDelegated: false,
                assignee: nil,
                assigneeContactId: nil,
                delegationStatus: nil
            )
            let updated: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            replaceTask(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateDelegationStatus(task: CTRLTask, status: String) async {
        do {
            let body = UpdateTaskBody(delegationStatus: status)
            let updated: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
            replaceTask(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func replaceTask(_ updated: CTRLTask) {
        if let idx = todayTasks.firstIndex(where: { $0.id == updated.id }) {
            todayTasks[idx] = updated
        }
        if let idx = inboxTasks.firstIndex(where: { $0.id == updated.id }) {
            inboxTasks[idx] = updated
        }
        tasks = todayTasks + inboxTasks
    }
}
