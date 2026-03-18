import Foundation

@MainActor
final class DelegationsViewModel: ObservableObject {
    @Published var delegations: [Delegation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var pendingCount: Int {
        delegations.filter { $0.status == "pendiente" }.count
    }

    func fetchDelegations() async {
        isLoading = true
        errorMessage = nil
        do {
            delegations = try await APIClient.shared.request(.delegations)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateDelegationBody) async {
        do {
            let created: Delegation = try await APIClient.shared.request(.delegations, body: body)
            delegations.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStatus(id: UUID, status: String) async {
        do {
            let body = UpdateDelegationBody(status: status)
            let updated: Delegation = try await APIClient.shared.request(.delegation(id: id), body: body)
            if let idx = delegations.firstIndex(where: { $0.id == id }) {
                delegations[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.delegation(id: id))
            delegations.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
