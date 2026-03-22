import Foundation

@MainActor
final class MeetingsViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var objectives: [Objective] = []
    @Published var suggestedTasks: [SuggestedTask] = []
    @Published var isLoading = false
    @Published var isProcessingMinutes = false
    @Published var errorMessage: String?

    @Published var todayMeetings: [Meeting] = []
    @Published var upcomingMeetings: [Meeting] = []
    @Published var productivity: MeetingProductivity?
    @Published var attendeeContacts: [String: Contact] = [:]

    func matchAttendeesWithContacts(attendees: [MeetingAttendee]) async {
        // Fetch all user contacts once
        if attendeeContacts.isEmpty {
            do {
                let contacts: [Contact] = try await APIClient.shared.request(.contacts)
                for c in contacts {
                    if let email = c.email?.lowercased(), !email.isEmpty {
                        attendeeContacts[email] = c
                    }
                }
            } catch { }
        }
    }

    func fetchMeetings() async {
        isLoading = true
        errorMessage = nil
        do {
            meetings = try await APIClient.shared.request(.meetings)
            // DEBUG: log attendees
            for m in meetings.prefix(5) {
                print("[MeetingsVM] \(m.title) — attendees: \(m.attendees?.count ?? -1), organizer: \(m.organizer ?? "nil")")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchToday() async {
        do {
            todayMeetings = try await APIClient.shared.request(.meetingsToday)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchUpcoming() async {
        do {
            upcomingMeetings = try await APIClient.shared.request(.meetingsUpcoming)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchByDate(_ date: Date) async -> [Meeting] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        do {
            return try await APIClient.shared.request(.meetingsByDate(date: df.string(from: date)))
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    func fetchAnalysis(period: String = "week", startDate: String? = nil, endDate: String? = nil) async -> MeetingAnalysis? {
        do {
            return try await APIClient.shared.request(
                .meetingsAnalysis(period: period, startDate: startDate, endDate: endDate)
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func fetchProductivity() async {
        do {
            productivity = try await APIClient.shared.request(.meetingsProductivity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    struct DeletePastResult: Codable { let deleted: Int }

    func deletePast() async -> Int {
        do {
            let result: DeletePastResult = try await APIClient.shared.request(
                .meetingsPast, method: "DELETE"
            )
            await fetchMeetings()
            await fetchToday()
            return result.deleted
        } catch {
            errorMessage = error.localizedDescription
            return 0
        }
    }

    // MARK: - Attendance & Scoring

    func updateAttendance(meetingId: UUID, status: String) async {
        struct Body: Encodable { let status: String }
        do {
            let updated: Meeting = try await APIClient.shared.request(
                .meetingAttendance(id: meetingId), method: "PATCH", body: Body(status: status)
            )
            updateLocal(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scoreImportance(meetingId: UUID) async {
        do {
            let updated: Meeting = try await APIClient.shared.request(
                .meetingScore(id: meetingId), method: "POST"
            )
            updateLocal(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delegateMeeting(meetingId: UUID, contactId: UUID, sendEmail: Bool) async -> Meeting? {
        struct Body: Encodable { let contactId: String; let sendEmail: Bool }
        do {
            let updated: Meeting = try await APIClient.shared.request(
                .meetingDelegate(id: meetingId),
                method: "POST",
                body: Body(contactId: contactId.uuidString, sendEmail: sendEmail)
            )
            updateLocal(updated)
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func updateLocal(_ meeting: Meeting) {
        if let idx = meetings.firstIndex(where: { $0.id == meeting.id }) {
            meetings[idx] = meeting
        }
        if let idx = todayMeetings.firstIndex(where: { $0.id == meeting.id }) {
            todayMeetings[idx] = meeting
        }
        if let idx = upcomingMeetings.firstIndex(where: { $0.id == meeting.id }) {
            upcomingMeetings[idx] = meeting
        }
    }

    func fetchObjectives() async {
        do {
            objectives = try await APIClient.shared.request(.objectives)
        } catch { /* silent */ }
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

    // MARK: - Objective linking

    func setObjective(meetingId: UUID, objectiveId: UUID?) async {
        struct Body: Encodable { let objectiveId: String? }
        do {
            let updated: Meeting = try await APIClient.shared.request(
                .meetingObjective(id: meetingId),
                method: "PATCH",
                body: Body(objectiveId: objectiveId?.uuidString)
            )
            if let idx = meetings.firstIndex(where: { $0.id == meetingId }) {
                meetings[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Minutes processing

    func processMinutes(text: String, meetingId: UUID?) async {
        isProcessingMinutes = true
        struct Body: Encodable { let text: String; let meetingId: String? }
        do {
            let tasks: [SuggestedTask] = try await APIClient.shared.request(
                .processMinutes,
                method: "POST",
                body: Body(text: text, meetingId: meetingId?.uuidString)
            )
            suggestedTasks = tasks
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessingMinutes = false
    }

    func confirmTasks(meetingId: UUID?) async -> ConfirmTasksResult? {
        let items = suggestedTasks.filter(\.included).map { t in
            ConfirmTaskItem(
                title: t.title,
                type: t.type,
                suggestedAssignee: t.suggestedAssignee,
                suggestedDueDate: t.suggestedDueDate,
                priorityLevel: t.priorityLevel,
                context: t.context,
                contactId: t.contactId
            )
        }
        let body = ConfirmTasksBody(
            tasks: items,
            meetingId: meetingId?.uuidString
        )
        do {
            let result: ConfirmTasksResult = try await APIClient.shared.request(
                .confirmTasks, method: "POST", body: body
            )
            suggestedTasks = []
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
