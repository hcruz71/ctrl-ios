import Foundation

@MainActor
final class MeetingsViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchMeetings() async {
        isLoading = true
        errorMessage = nil
        do {
            meetings = try await APIClient.shared.request(.meetings)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func create(_ body: CreateMeetingBody) async {
        do {
            let created: Meeting = try await APIClient.shared.request(.meetings, body: body)
            meetings.insert(created, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(id: UUID, body: UpdateMeetingBody) async {
        do {
            let updated: Meeting = try await APIClient.shared.request(.meeting(id: id), body: body)
            if let idx = meetings.firstIndex(where: { $0.id == id }) {
                meetings[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: UUID) async {
        do {
            try await APIClient.shared.requestVoid(.meeting(id: id))
            meetings.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
