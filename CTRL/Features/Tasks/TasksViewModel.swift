import Foundation

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [CTRLTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchTasks() async {
        isLoading = true
        errorMessage = nil
        do {
            tasks = try await APIClient.shared.request(.tasks)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateTaskBody) async {
        do {
            let created: CTRLTask = try await APIClient.shared.request(.tasks, body: body)
            tasks.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleDone(task: CTRLTask) async {
        do {
            let body = UpdateTaskBody(done: !task.done)
            let updated: CTRLTask = try await APIClient.shared.request(.task(id: task.id), body: body)
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.task(id: id))
            tasks.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
