import Foundation

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            projects = try await APIClient.shared.request(.projects)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateProjectBody) async {
        do {
            let created: Project = try await APIClient.shared.request(.projects, body: body)
            projects.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(id: UUID, body: UpdateProjectBody) async {
        do {
            let updated: Project = try await APIClient.shared.request(.project(id: id), body: body)
            if let idx = projects.firstIndex(where: { $0.id == id }) {
                projects[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.project(id: id))
            projects.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchProjectTasks(id: UUID) async -> [CTRLTask] {
        do {
            return try await APIClient.shared.request(.projectTasks(id: id))
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func getSummary(id: UUID) async -> ProjectSummary? {
        do {
            return try await APIClient.shared.request(.projectSummary(id: id))
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
