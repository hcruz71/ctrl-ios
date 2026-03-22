import Foundation

@MainActor
final class ObjectivesViewModel: ObservableObject {
    @Published var objectives: [Objective] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchObjectives() async {
        isLoading = true
        errorMessage = nil
        do {
            objectives = try await APIClient.shared.request(.objectives)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateObjectiveBody) async {
        do {
            let created: Objective = try await APIClient.shared.request(.objectives, body: body)
            objectives.insert(created, at: 0)
        } catch {
            print("[ObjectivesVM] Create decode error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func updateProgress(id: UUID, progress: Int) async {
        do {
            let body = UpdateObjectiveBody(progress: progress)
            let updated: Objective = try await APIClient.shared.request(.objective(id: id), body: body)
            if let idx = objectives.firstIndex(where: { $0.id == id }) {
                objectives[idx] = updated
            }
        } catch {
            print("[ObjectivesVM] Update decode error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func update(id: UUID, body: UpdateObjectiveBody) async {
        do {
            let updated: Objective = try await APIClient.shared.request(.objective(id: id), body: body)
            if let idx = objectives.firstIndex(where: { $0.id == id }) {
                objectives[idx] = updated
            }
        } catch {
            print("[ObjectivesVM] Update error: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.objective(id: id))
            objectives.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
