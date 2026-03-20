import Foundation

struct Delegation: Codable, Identifiable {
    let id: UUID
    var title: String
    var assignee: String
    var status: String
    var dueDate: String?
    var notes: String?
    var taskId: UUID?
    var contactId: UUID?
    var contact: Contact?
    var emailSentAt: Date?
    var emailDraft: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct CreateDelegationBody: Encodable {
    var title: String
    var assignee: String
    var status: String = "pendiente"
    var dueDate: String?
    var notes: String?
    var taskId: UUID?
    var contactId: String?
}

struct UpdateDelegationBody: Encodable {
    var title: String?
    var assignee: String?
    var status: String?
    var dueDate: String?
    var notes: String?
    var contactId: String?
}

struct DelegationEmailContext: Encodable {
    var objetivoVinculado: String?
    var contextoAdicional: String?
    var recursosDisponibles: String?
    var fechaPrimerCheckpoint: String?
    var nivelAutonomia: String?
    var tono: String?
}

struct PrepareEmailBody: Encodable {
    var context: DelegationEmailContext
    var send: Bool
}

struct SmartEmailResult: Codable {
    let emailSubject: String
    let emailDraft: String
    let emailSentAt: Date?
}
