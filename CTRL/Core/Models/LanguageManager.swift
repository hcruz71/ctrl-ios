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
        "tab.analysis":     ["es": "Analisis",     "en": "Analysis",      "pt": "Analise",      "fr": "Analyse",      "de": "Analyse"],

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

        // Toolbar
        "toolbar.settings": ["es": "Configuraciones", "en": "Settings",       "pt": "Configuracoes",  "fr": "Parametres",      "de": "Einstellungen"],
        "toolbar.help":     ["es": "Ayuda",            "en": "Help",           "pt": "Ajuda",          "fr": "Aide",            "de": "Hilfe"],

        // Emails
        "emails.title":    ["es": "Correos",            "en": "Emails",            "pt": "E-mails",          "fr": "E-mails",           "de": "E-Mails"],
        "emails.analyze":  ["es": "Analizar con IA",    "en": "Analyze with AI",   "pt": "Analisar com IA",  "fr": "Analyser avec IA",  "de": "Mit KI analysieren"],
        "emails.import":   ["es": "Importar archivo",   "en": "Import file",       "pt": "Importar arquivo", "fr": "Importer fichier",  "de": "Datei importieren"],
        "emails.stats":    ["es": "Estadisticas",       "en": "Statistics",        "pt": "Estatisticas",     "fr": "Statistiques",      "de": "Statistiken"],
        "emails.urgent":   ["es": "Urgentes",           "en": "Urgent",            "pt": "Urgente",          "fr": "Urgent",            "de": "Dringend"],
        "emails.action":   ["es": "Requiere accion",    "en": "Requires action",   "pt": "Requer acao",      "fr": "Action requise",    "de": "Aktion erforderlich"],
        "emails.info":     ["es": "Informativo",        "en": "Informative",       "pt": "Informativo",      "fr": "Informatif",        "de": "Informativ"],
        "emails.ignore":   ["es": "Ignorar",            "en": "Ignore",            "pt": "Ignorar",          "fr": "Ignorer",           "de": "Ignorieren"],
        "emails.compose":  ["es": "Nuevo correo",       "en": "New email",         "pt": "Novo e-mail",      "fr": "Nouveau e-mail",    "de": "Neue E-Mail"],
        "emails.clean":    ["es": "Limpiar analisis",   "en": "Clear analysis",    "pt": "Limpar analise",   "fr": "Effacer l'analyse", "de": "Analyse loschen"],

        // Meetings (new)
        "meetings.clean_imported":  ["es": "Limpiar importadas",             "en": "Clear imported",            "pt": "Limpar importadas",        "fr": "Effacer importees",            "de": "Importierte loschen"],
        "meetings.delete_all":      ["es": "Eliminar todas las reuniones",   "en": "Delete all meetings",       "pt": "Excluir todas reunioes",   "fr": "Supprimer toutes reunions",    "de": "Alle Besprechungen loschen"],
        "meetings.no_time":         ["es": "Sin hora definida",              "en": "No time defined",           "pt": "Sem hora definida",        "fr": "Sans heure definie",           "de": "Keine Zeit definiert"],
        "meetings.link_project":    ["es": "Vincular a proyecto",            "en": "Link to project",           "pt": "Vincular ao projeto",      "fr": "Lier au projet",               "de": "Mit Projekt verknupfen"],
        "meetings.unlink":          ["es": "Desvincular",                    "en": "Unlink",                    "pt": "Desvincular",              "fr": "Dissocier",                    "de": "Verknupfung aufheben"],
        "meetings.analysis":        ["es": "Analisis",                       "en": "Analysis",                  "pt": "Analise",                  "fr": "Analyse",                      "de": "Analyse"],
        "meetings.preparation":     ["es": "Preparacion",                    "en": "Preparation",               "pt": "Preparacao",               "fr": "Preparation",                  "de": "Vorbereitung"],
        "meetings.action_items":    ["es": "Elementos de accion",            "en": "Action items",              "pt": "Itens de acao",            "fr": "Elements d'action",            "de": "Aktionspunkte"],

        // Projects
        "projects.title":            ["es": "Proyectos",             "en": "Projects",           "pt": "Projetos",            "fr": "Projets",              "de": "Projekte"],
        "projects.new":              ["es": "Nuevo proyecto",        "en": "New project",        "pt": "Novo projeto",        "fr": "Nouveau projet",       "de": "Neues Projekt"],
        "projects.edit":             ["es": "Editar proyecto",       "en": "Edit project",       "pt": "Editar projeto",      "fr": "Modifier projet",      "de": "Projekt bearbeiten"],
        "projects.gantt":            ["es": "Diagrama Gantt",        "en": "Gantt Chart",        "pt": "Grafico Gantt",       "fr": "Diagramme Gantt",      "de": "Gantt-Diagramm"],
        "projects.linked_objective": ["es": "Objetivo vinculado",    "en": "Linked objective",   "pt": "Objetivo vinculado",  "fr": "Objectif lie",         "de": "Verknupftes Ziel"],
        "projects.progress":         ["es": "Avance",               "en": "Progress",           "pt": "Progresso",           "fr": "Progression",          "de": "Fortschritt"],
        "projects.status.active":    ["es": "Activo",               "en": "Active",             "pt": "Ativo",               "fr": "Actif",                "de": "Aktiv"],
        "projects.status.paused":    ["es": "Pausado",              "en": "Paused",             "pt": "Pausado",             "fr": "En pause",             "de": "Pausiert"],
        "projects.status.completed": ["es": "Completado",           "en": "Completed",          "pt": "Concluido",           "fr": "Termine",              "de": "Abgeschlossen"],
        "projects.status.cancelled": ["es": "Cancelado",            "en": "Cancelled",          "pt": "Cancelado",           "fr": "Annule",               "de": "Abgebrochen"],

        // Tasks (new)
        "tasks.delegated":   ["es": "Delegadas",          "en": "Delegated",        "pt": "Delegadas",        "fr": "Deleguees",         "de": "Delegiert"],
        "tasks.recover":     ["es": "Recuperar para mi",  "en": "Recover for me",   "pt": "Recuperar para mim","fr": "Recuperer pour moi","de": "Fur mich zuruckholen"],
        "tasks.delegate":    ["es": "Delegar",            "en": "Delegate",         "pt": "Delegar",          "fr": "Deleguer",          "de": "Delegieren"],
        "tasks.send_email":  ["es": "Enviar correo",      "en": "Send email",       "pt": "Enviar e-mail",    "fr": "Envoyer e-mail",    "de": "E-Mail senden"],
        "tasks.start_date":  ["es": "Fecha inicio",       "en": "Start date",       "pt": "Data inicio",      "fr": "Date debut",        "de": "Startdatum"],
        "tasks.end_date":    ["es": "Fecha fin",          "en": "End date",         "pt": "Data fim",         "fr": "Date fin",          "de": "Enddatum"],
        "tasks.duration":    ["es": "Duracion",           "en": "Duration",         "pt": "Duracao",          "fr": "Duree",             "de": "Dauer"],

        // Contacts (new)
        "contacts.network":           ["es": "Tipo de red",           "en": "Network type",            "pt": "Tipo de rede",          "fr": "Type de reseau",          "de": "Netzwerktyp"],
        "contacts.influence":         ["es": "Nivel de influencia",   "en": "Influence level",         "pt": "Nivel de influencia",   "fr": "Niveau d'influence",      "de": "Einflussniveau"],
        "contacts.strength":          ["es": "Fuerza de relacion",    "en": "Relationship strength",   "pt": "Forca do relacionamento","fr": "Force de la relation",   "de": "Beziehungsstarke"],
        "contacts.notes":             ["es": "Notas de relacion",     "en": "Relationship notes",      "pt": "Notas de relacionamento","fr": "Notes de relation",      "de": "Beziehungsnotizen"],
        "contacts.add_from_meeting":  ["es": "Agregar a contactos",   "en": "Add to contacts",         "pt": "Adicionar aos contatos","fr": "Ajouter aux contacts",    "de": "Zu Kontakten hinzufugen"],

        // Objectives (new)
        "objectives.smart":      ["es": "Metodologia SMART",       "en": "SMART Methodology",     "pt": "Metodologia SMART",     "fr": "Methodologie SMART",     "de": "SMART-Methodik"],
        "objectives.kpi":        ["es": "Indicador KPI",           "en": "KPI Indicator",         "pt": "Indicador KPI",         "fr": "Indicateur KPI",         "de": "KPI-Indikator"],
        "objectives.measure":    ["es": "Registrar medicion",      "en": "Record measurement",    "pt": "Registrar medicao",     "fr": "Enregistrer mesure",     "de": "Messung erfassen"],
        "objectives.baseline":   ["es": "Valor inicial",           "en": "Baseline value",        "pt": "Valor inicial",         "fr": "Valeur de base",         "de": "Ausgangswert"],
        "objectives.target":     ["es": "Meta",                    "en": "Target",                "pt": "Meta",                  "fr": "Cible",                  "de": "Ziel"],
        "objectives.current":    ["es": "Valor actual",            "en": "Current value",         "pt": "Valor atual",           "fr": "Valeur actuelle",        "de": "Aktueller Wert"],
        "objectives.unit":       ["es": "Unidad",                  "en": "Unit",                  "pt": "Unidade",               "fr": "Unite",                  "de": "Einheit"],
        "objectives.frequency":  ["es": "Frecuencia",              "en": "Frequency",             "pt": "Frequencia",            "fr": "Frequence",              "de": "Haufigkeit"],
        "objectives.completion": ["es": "Criterio de cumplimiento","en": "Completion criteria",   "pt": "Criterio de conclusao", "fr": "Critere d'achevement",   "de": "Abschlusskriterium"],
        "objectives.reduction":  ["es": "Objetivo de reduccion",   "en": "Reduction goal",        "pt": "Objetivo de reducao",   "fr": "Objectif de reduction",  "de": "Reduktionsziel"],
        "objectives.increment":  ["es": "Objetivo de incremento",  "en": "Increment goal",        "pt": "Objetivo de incremento","fr": "Objectif d'increment",   "de": "Steigerungsziel"],

        // Settings
        "settings.title":         ["es": "Configuraciones",            "en": "Settings",                 "pt": "Configuracoes",            "fr": "Parametres",                "de": "Einstellungen"],
        "settings.calendar":      ["es": "Calendario",                 "en": "Calendar",                 "pt": "Calendario",               "fr": "Calendrier",                "de": "Kalender"],
        "settings.schedule":      ["es": "Horario y disponibilidad",   "en": "Schedule & availability",  "pt": "Horario e disponibilidade","fr": "Horaire et disponibilite", "de": "Zeitplan und Verfugbarkeit"],
        "settings.notifications": ["es": "Notificaciones",             "en": "Notifications",            "pt": "Notificacoes",             "fr": "Notifications",             "de": "Benachrichtigungen"],
        "settings.usage":         ["es": "Uso de IA",                  "en": "AI Usage",                 "pt": "Uso de IA",                "fr": "Utilisation IA",            "de": "KI-Nutzung"],
        "settings.absences":      ["es": "Ausencias",                  "en": "Absences",                 "pt": "Ausencias",                "fr": "Absences",                  "de": "Abwesenheiten"],

        // Absences
        "absence.vacation":       ["es": "Vacaciones",                       "en": "Vacation",                       "pt": "Ferias",                      "fr": "Vacances",                     "de": "Urlaub"],
        "absence.leave":          ["es": "Licencia",                         "en": "Leave",                          "pt": "Licenca",                     "fr": "Conge",                        "de": "Urlaub"],
        "absence.travel":         ["es": "Viaje",                            "en": "Travel",                         "pt": "Viagem",                      "fr": "Voyage",                       "de": "Reise"],
        "absence.other":          ["es": "Otra",                             "en": "Other",                          "pt": "Outra",                       "fr": "Autre",                        "de": "Andere"],
        "absence.substitute":     ["es": "Sustituto",                        "en": "Substitute",                     "pt": "Substituto",                  "fr": "Remplacant",                   "de": "Stellvertreter"],
        "absence.generate_docs":  ["es": "Generar documentos de entrega",    "en": "Generate handover documents",    "pt": "Gerar documentos de entrega", "fr": "Generer documents de passation","de": "Ubergabedokumente erstellen"],

        // Analysis
        "analysis.period.day":    ["es": "Hoy",           "en": "Today",    "pt": "Hoje",           "fr": "Aujourd'hui",   "de": "Heute"],
        "analysis.period.week":   ["es": "Semana",        "en": "Week",     "pt": "Semana",         "fr": "Semaine",       "de": "Woche"],
        "analysis.period.month":  ["es": "Mes",           "en": "Month",    "pt": "Mes",            "fr": "Mois",          "de": "Monat"],
        "analysis.period.custom": ["es": "Personalizado", "en": "Custom",   "pt": "Personalizado",  "fr": "Personnalise",  "de": "Benutzerdefiniert"],
        "analysis.ai_cost":       ["es": "Este analisis usara interacciones de IA", "en": "This analysis will use AI interactions", "pt": "Esta analise usara interacoes de IA", "fr": "Cette analyse utilisera des interactions IA", "de": "Diese Analyse verwendet KI-Interaktionen"],

        // Help
        "help.title":        ["es": "Ayuda",          "en": "Help",         "pt": "Ajuda",       "fr": "Aide",                "de": "Hilfe"],
        "help.coming_soon":  ["es": "Proximamente",   "en": "Coming soon",  "pt": "Em breve",    "fr": "Bientot disponible",  "de": "Demnachst"],
    ]
}
