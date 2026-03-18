import Foundation

@MainActor
final class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchContacts() async {
        isLoading = true
        errorMessage = nil
        do {
            contacts = try await APIClient.shared.request(.contacts)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateContactBody) async {
        do {
            let created: Contact = try await APIClient.shared.request(.contacts, body: body)
            contacts.insert(created, at: 0)
            // Re-sort alphabetically after insert
            contacts.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(id: UUID, body: UpdateContactBody) async {
        do {
            let updated: Contact = try await APIClient.shared.request(.contact(id: id), body: body)
            if let idx = contacts.firstIndex(where: { $0.id == id }) {
                contacts[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.contact(id: id))
            contacts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
