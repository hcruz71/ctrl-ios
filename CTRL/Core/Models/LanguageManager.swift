import Foundation
import Combine

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var currentLanguage: String {
        didSet { UserDefaults.standard.set(currentLanguage, forKey: "appLanguage") }
    }

    static let supportedLanguages: [(code: String, label: String, flag: String)] = [
        ("es", "Espanol", "🇲🇽🇪🇸"),
        ("en", "English", "🇺🇸🇬🇧"),
        ("pt", "Portugues", "🇧🇷🇵🇹"),
        ("fr", "Francais", "🇫🇷"),
        ("de", "Deutsch", "🇩🇪"),
    ]

    static func label(for code: String) -> String {
        supportedLanguages.first { $0.code == code }?.label ?? "Espanol"
    }

    // MARK: - Translation

    func t(_ key: String) -> String {
        translations[key]?[currentLanguage] ?? translations[key]?["es"] ?? key
    }

    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "es"
    }

    // MARK: - Translation table

    private let translations: [String: [String: String]] = [
        // Tabs
        "tab.objectives":   ["es": "Objetivos",    "en": "Objectives",    "pt": "Objetivos",    "fr": "Objectifs",    "de": "Ziele"],
        "tab.meetings":     ["es": "Reuniones",    "en": "Meetings",      "pt": "Reunioes",     "fr": "Reunions",     "de": "Besprechungen"],
        "tab.assistant":    ["es": "Asistente",    "en": "Assistant",     "pt": "Assistente",   "fr": "Assistant",    "de": "Assistent"],
        "tab.tasks":        ["es": "Tareas",       "en": "Tasks",         "pt": "Tarefas",      "fr": "Taches",       "de": "Aufgaben"],
        "tab.people":       ["es": "Personas",     "en": "People",        "pt": "Pessoas",      "fr": "Personnes",    "de": "Personen"],

        // Priorities
        "priority.urgent":    ["es": "Urgentes",      "en": "Urgent",       "pt": "Urgente",       "fr": "Urgent",       "de": "Dringend"],
        "priority.important": ["es": "Importantes",   "en": "Important",    "pt": "Importante",    "fr": "Important",    "de": "Wichtig"],
        "priority.pending":   ["es": "Pendientes",    "en": "Pending",      "pt": "Pendente",      "fr": "En attente",   "de": "Ausstehend"],
        "priority.inbox":     ["es": "Sin clasificar","en": "Unclassified", "pt": "Sem classificar","fr": "Non classe",  "de": "Nicht klassifiziert"],

        // Common actions
        "action.save":   ["es": "Guardar",   "en": "Save",    "pt": "Salvar",    "fr": "Enregistrer", "de": "Speichern"],
        "action.cancel": ["es": "Cancelar",  "en": "Cancel",  "pt": "Cancelar",  "fr": "Annuler",     "de": "Abbrechen"],
        "action.delete": ["es": "Eliminar",  "en": "Delete",  "pt": "Excluir",   "fr": "Supprimer",   "de": "Loschen"],
        "action.edit":   ["es": "Editar",    "en": "Edit",    "pt": "Editar",    "fr": "Modifier",    "de": "Bearbeiten"],
        "action.add":    ["es": "Agregar",   "en": "Add",     "pt": "Adicionar", "fr": "Ajouter",     "de": "Hinzufugen"],
        "action.close":  ["es": "Cerrar",    "en": "Close",   "pt": "Fechar",    "fr": "Fermer",      "de": "Schliessen"],
        "action.search": ["es": "Buscar",    "en": "Search",  "pt": "Buscar",    "fr": "Rechercher",  "de": "Suchen"],

        // Objectives
        "objectives.title":          ["es": "Objetivos",          "en": "Objectives",         "pt": "Objetivos",          "fr": "Objectifs",             "de": "Ziele"],
        "objectives.empty":          ["es": "Sin objetivos",      "en": "No objectives yet",  "pt": "Sem objetivos",      "fr": "Pas d'objectifs",       "de": "Noch keine Ziele"],
        "objectives.add":            ["es": "Nuevo objetivo",     "en": "New objective",      "pt": "Novo objetivo",      "fr": "Nouvel objectif",       "de": "Neues Ziel"],
        "objectives.all":            ["es": "Todos",              "en": "All",                "pt": "Todos",              "fr": "Tous",                  "de": "Alle"],
        "objectives.area.personal":  ["es": "Personal",           "en": "Personal",           "pt": "Pessoal",            "fr": "Personnel",             "de": "Personlich"],
        "objectives.area.work":      ["es": "Laboral",            "en": "Work",               "pt": "Trabalho",           "fr": "Travail",               "de": "Arbeit"],
        "objectives.area.spiritual": ["es": "Espiritual",         "en": "Spiritual",          "pt": "Espiritual",         "fr": "Spirituel",             "de": "Spirituell"],
        "objectives.area.financial": ["es": "Financiero",         "en": "Financial",          "pt": "Financeiro",         "fr": "Financier",             "de": "Finanziell"],
        "objectives.area.family":    ["es": "Familiar",           "en": "Family",             "pt": "Familiar",           "fr": "Familial",              "de": "Familie"],
        "objectives.area.business":  ["es": "Negocio",            "en": "Business",           "pt": "Negocio",            "fr": "Affaires",              "de": "Geschaft"],
        "objectives.status.active":  ["es": "Activos",            "en": "Active",             "pt": "Ativos",             "fr": "Actifs",                "de": "Aktiv"],
        "objectives.status.completed":["es":"Completados",        "en": "Completed",          "pt": "Concluidos",         "fr": "Termines",              "de": "Abgeschlossen"],
        "objectives.status.paused":  ["es": "Pausados",           "en": "Paused",             "pt": "Pausados",           "fr": "En pause",              "de": "Pausiert"],

        // Meetings
        "meetings.title":      ["es": "Reuniones",            "en": "Meetings",            "pt": "Reunioes",           "fr": "Reunions",             "de": "Besprechungen"],
        "meetings.today":      ["es": "Hoy",                  "en": "Today",               "pt": "Hoje",               "fr": "Aujourd'hui",          "de": "Heute"],
        "meetings.upcoming":   ["es": "Proximas",             "en": "Upcoming",            "pt": "Proximas",            "fr": "A venir",              "de": "Bevorstehend"],
        "meetings.all":        ["es": "Todas",                "en": "All",                 "pt": "Todas",               "fr": "Toutes",               "de": "Alle"],
        "meetings.empty":      ["es": "Sin reuniones hoy",    "en": "No meetings today",   "pt": "Sem reunioes hoje",   "fr": "Pas de reunions",      "de": "Keine Besprechungen"],
        "meetings.new":        ["es": "Nueva reunion",        "en": "New meeting",         "pt": "Nova reuniao",        "fr": "Nouvelle reunion",     "de": "Neue Besprechung"],
        "meetings.noObjective":["es": "Sin objetivo",         "en": "No objective",        "pt": "Sem objetivo",        "fr": "Sans objectif",        "de": "Kein Ziel"],
        "meetings.withObj":    ["es": "con objetivo",         "en": "with objective",      "pt": "com objetivo",        "fr": "avec objectif",        "de": "mit Ziel"],
        "meetings.countToday": ["es": "reuniones hoy",        "en": "meetings today",      "pt": "reunioes hoje",       "fr": "reunions aujourd'hui", "de": "Besprechungen heute"],

        // Tasks
        "tasks.title":    ["es": "Tareas",              "en": "Tasks",             "pt": "Tarefas",            "fr": "Taches",            "de": "Aufgaben"],
        "tasks.empty":    ["es": "Sin tareas",          "en": "No tasks",          "pt": "Sem tarefas",        "fr": "Pas de taches",     "de": "Keine Aufgaben"],
        "tasks.add":      ["es": "Nueva tarea",         "en": "New task",          "pt": "Nova tarefa",        "fr": "Nouvelle tache",    "de": "Neue Aufgabe"],
        "tasks.urgentA":  ["es": "URGENTES (A)",        "en": "URGENT (A)",        "pt": "URGENTES (A)",       "fr": "URGENT (A)",        "de": "DRINGEND (A)"],
        "tasks.importantB":["es":"IMPORTANTES (B)",     "en": "IMPORTANT (B)",     "pt": "IMPORTANTES (B)",    "fr": "IMPORTANT (B)",     "de": "WICHTIG (B)"],
        "tasks.pendingC": ["es": "PENDIENTES (C)",      "en": "PENDING (C)",       "pt": "PENDENTES (C)",      "fr": "EN ATTENTE (C)",    "de": "AUSSTEHEND (C)"],

        // Delegations
        "delegations.title": ["es": "Delegaciones",    "en": "Delegations",      "pt": "Delegacoes",         "fr": "Delegations",       "de": "Delegierungen"],
        "delegations.empty": ["es": "Sin delegaciones", "en": "No delegations",   "pt": "Sem delegacoes",     "fr": "Pas de delegations","de": "Keine Delegierungen"],

        // Contacts
        "contacts.title": ["es": "Contactos",  "en": "Contacts",  "pt": "Contatos",  "fr": "Contacts",  "de": "Kontakte"],
        "contacts.empty": ["es": "Sin contactos","en":"No contacts","pt":"Sem contatos","fr":"Pas de contacts","de":"Keine Kontakte"],

        // Profile
        "profile.title":         ["es": "Perfil",              "en": "Profile",            "pt": "Perfil",              "fr": "Profil",               "de": "Profil"],
        "profile.logout":        ["es": "Cerrar sesion",       "en": "Sign out",           "pt": "Sair",                "fr": "Se deconnecter",       "de": "Abmelden"],
        "profile.assistant":     ["es": "Mi Asistente",        "en": "My Assistant",       "pt": "Meu Assistente",      "fr": "Mon Assistant",        "de": "Mein Assistent"],
        "profile.voice":         ["es": "Voz del Asistente",   "en": "Assistant Voice",    "pt": "Voz do Assistente",   "fr": "Voix de l'Assistant",  "de": "Assistentenstimme"],
        "profile.schedule":      ["es": "Horario y Modos",     "en": "Schedule & Modes",   "pt": "Horario e Modos",     "fr": "Horaire et Modes",     "de": "Zeitplan und Modi"],
        "profile.language":      ["es": "Idioma",              "en": "Language",            "pt": "Idioma",              "fr": "Langue",               "de": "Sprache"],
        "profile.notifications": ["es": "Notificaciones",      "en": "Notifications",       "pt": "Notificacoes",       "fr": "Notifications",        "de": "Benachrichtigungen"],
        "profile.saveChanges":   ["es": "Guardar cambios",     "en": "Save changes",       "pt": "Salvar alteracoes",   "fr": "Enregistrer",          "de": "Speichern"],

        // Modes
        "mode.work":     ["es": "Trabajo",    "en": "Work",      "pt": "Trabalho",  "fr": "Travail",   "de": "Arbeit"],
        "mode.personal": ["es": "Personal",   "en": "Personal",  "pt": "Pessoal",   "fr": "Personnel", "de": "Personlich"],
        "mode.rest":     ["es": "Descanso",   "en": "Rest",      "pt": "Descanso",  "fr": "Repos",     "de": "Ruhe"],
        "mode.vacation": ["es": "Vacaciones", "en": "Vacation",  "pt": "Ferias",    "fr": "Vacances",  "de": "Urlaub"],

        // Loading
        "loading.session": ["es": "Cargando sesion...", "en": "Loading session...", "pt": "Carregando sessao...", "fr": "Chargement...", "de": "Sitzung laden..."],
    ]
}
