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
        "action.search":  ["es": "Buscar",    "en": "Search",  "pt": "Buscar",    "fr": "Rechercher",  "de": "Suchen"],
        "action.confirm": ["es": "Confirmar", "en": "Confirm", "pt": "Confirmar", "fr": "Confirmer",   "de": "Bestatigen"],

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

        // Profile (new)
        "profile.byok": ["es": "Usar mi propia API Key de Claude AI", "en": "Use my own Claude AI API Key", "pt": "Usar minha própria API Key do Claude AI", "fr": "Utiliser ma propre clé API Claude AI", "de": "Eigenen Claude AI API-Schlüssel verwenden"],
        "profile.help_section":           ["es": "Guia y Configuracion",                                                   "en": "Guide & Settings",                                                                "pt": "Guia e Configuracoes",                                                            "fr": "Guide et Parametres",                                                              "de": "Anleitung und Einstellungen"],
        "profile.restart_onboarding":     ["es": "Ver guia de inicio",                                                     "en": "View getting started guide",                                                      "pt": "Ver guia de inicio",                                                              "fr": "Voir le guide de demarrage",                                                       "de": "Erste-Schritte-Anleitung anzeigen"],
        "profile.restart_onboarding_msg": ["es": "Se mostrara la guia de inicio nuevamente. Tu informacion no se perdera.", "en": "The getting started guide will be shown again. Your information will not be lost.", "pt": "O guia de inicio sera exibido novamente. Suas informacoes nao serao perdidas.",     "fr": "Le guide de demarrage sera affiche a nouveau. Vos informations ne seront pas perdues.", "de": "Die Erste-Schritte-Anleitung wird erneut angezeigt. Ihre Informationen gehen nicht verloren."],

        // Onboarding
        "onboarding.welcome":      ["es": "Bienvenido a CTRL",                      "en": "Welcome to CTRL",                     "pt": "Bem-vindo ao CTRL",                "fr": "Bienvenue dans CTRL",              "de": "Willkommen bei CTRL"],
        "onboarding.subtitle":     ["es": "Tu asistente ejecutivo personal con IA",  "en": "Your personal AI executive assistant","pt": "Seu assistente executivo com IA",   "fr": "Votre assistant executif avec IA",  "de": "Ihr personlicher KI-Assistent"],
        "onboarding.start":        ["es": "Comenzar",        "en": "Get Started",    "pt": "Comecar",        "fr": "Commencer",       "de": "Loslegen"],
        "onboarding.skip":         ["es": "Saltar",          "en": "Skip",           "pt": "Pular",          "fr": "Passer",          "de": "Uberspringen"],
        "onboarding.later":        ["es": "Lo hare despues", "en": "I'll do it later","pt": "Farei depois",   "fr": "Plus tard",       "de": "Spater"],
        "onboarding.finish":       ["es": "Comenzar a usar CTRL","en": "Start using CTRL","pt": "Comecar a usar CTRL","fr": "Commencer CTRL","de": "CTRL verwenden"],
        "onboarding.step1.title":  ["es": "Comienza con un objetivo",        "en": "Start with an objective",       "pt": "Comece com um objetivo",        "fr": "Commencez avec un objectif",      "de": "Beginnen Sie mit einem Ziel"],
        "onboarding.step2.title":  ["es": "Tus reuniones en un solo lugar",  "en": "Your meetings in one place",    "pt": "Suas reunioes em um so lugar",  "fr": "Vos reunions en un seul endroit", "de": "Ihre Besprechungen an einem Ort"],
        "onboarding.step3.title":  ["es": "Tu red ejecutiva",                "en": "Your executive network",        "pt": "Sua rede executiva",            "fr": "Votre reseau executif",           "de": "Ihr Fuehrungsnetzwerk"],

        // Objective Areas
        "area.health":       ["es": "Salud & Bienestar",       "en": "Health & Wellness",       "pt": "Saude & Bem-estar",       "fr": "Sante & Bien-etre",          "de": "Gesundheit & Wohlbefinden"],
        "area.professional": ["es": "Profesional & Negocios",  "en": "Professional & Business", "pt": "Profissional & Negocios", "fr": "Professionnel & Affaires",   "de": "Beruflich & Geschaftlich"],
        "area.financial":    ["es": "Financiero",              "en": "Financial",               "pt": "Financeiro",              "fr": "Financier",                  "de": "Finanziell"],
        "area.family":       ["es": "Familia & Relaciones",    "en": "Family & Relationships",  "pt": "Familia & Relacionamentos","fr": "Famille & Relations",       "de": "Familie & Beziehungen"],
        "area.growth":       ["es": "Crecimiento Personal",    "en": "Personal Growth",         "pt": "Crescimento Pessoal",     "fr": "Croissance Personnelle",     "de": "Personliches Wachstum"],
        "area.spiritual":    ["es": "Espiritual & Recreacion", "en": "Spiritual & Recreation",  "pt": "Espiritual & Recreacao",  "fr": "Spirituel & Loisirs",        "de": "Spirituell & Freizeit"],

        // SMART steps
        "smart.step1":          ["es": "Informacion basica",    "en": "Basic information",      "pt": "Informacoes basicas",     "fr": "Informations de base",     "de": "Grundinformationen"],
        "smart.step2":          ["es": "Metodologia SMART",     "en": "SMART Methodology",      "pt": "Metodologia SMART",       "fr": "Methodologie SMART",       "de": "SMART-Methodik"],
        "smart.step3":          ["es": "KPI de medicion",       "en": "Measurement KPI",        "pt": "KPI de medicao",          "fr": "KPI de mesure",            "de": "Mess-KPI"],
        "smart.step4":          ["es": "Resumen",               "en": "Summary",                "pt": "Resumo",                  "fr": "Resume",                   "de": "Zusammenfassung"],
        "smart.create":         ["es": "Crear objetivo",        "en": "Create objective",       "pt": "Criar objetivo",          "fr": "Creer objectif",           "de": "Ziel erstellen"],
        "smart.save":           ["es": "Guardar cambios",       "en": "Save changes",           "pt": "Salvar alteracoes",       "fr": "Enregistrer",              "de": "Anderungen speichern"],
        "smart.specific":       ["es": "Especifico",            "en": "Specific",               "pt": "Especifico",              "fr": "Specifique",               "de": "Spezifisch"],
        "smart.measurable":     ["es": "Medible",               "en": "Measurable",             "pt": "Mensuravel",              "fr": "Mesurable",                "de": "Messbar"],
        "smart.achievable":     ["es": "Alcanzable",            "en": "Achievable",             "pt": "Alcancavel",              "fr": "Realisable",               "de": "Erreichbar"],
        "smart.relevant":       ["es": "Relevante",             "en": "Relevant",               "pt": "Relevante",               "fr": "Pertinent",                "de": "Relevant"],
        "smart.timebound":      ["es": "Tiempo definido",       "en": "Time-bound",             "pt": "Tempo definido",          "fr": "Delimite dans le temps",   "de": "Zeitgebunden"],
        "smart.what_goal":      ["es": "Que exactamente quieres lograr?",  "en": "What exactly do you want to achieve?",  "pt": "O que exatamente voce quer alcancar?",  "fr": "Qu'est-ce que vous voulez accomplir?",  "de": "Was genau mochten Sie erreichen?"],
        "smart.how_measure":    ["es": "Como sabras que lo lograste?",     "en": "How will you know you achieved it?",    "pt": "Como sabera que conseguiu?",             "fr": "Comment saurez-vous que vous l'avez realise?", "de": "Wie werden Sie wissen, dass Sie es erreicht haben?"],
        "smart.why_achievable": ["es": "Por que puedes lograrlo?",         "en": "Why can you achieve it?",               "pt": "Por que voce pode alcanca-lo?",          "fr": "Pourquoi pouvez-vous y parvenir?",      "de": "Warum konnen Sie es erreichen?"],
        "smart.why_relevant":   ["es": "Por que es importante ahora?",     "en": "Why is it important now?",              "pt": "Por que e importante agora?",            "fr": "Pourquoi est-ce important maintenant?", "de": "Warum ist es jetzt wichtig?"],
        "smart.deadline":       ["es": "Fecha limite",          "en": "Deadline",               "pt": "Prazo",                   "fr": "Date limite",              "de": "Frist"],
        "smart.horizon":        ["es": "Horizonte",             "en": "Horizon",                "pt": "Horizonte",               "fr": "Horizon",                  "de": "Horizont"],
        "smart.title_field":    ["es": "Titulo del objetivo",   "en": "Objective title",        "pt": "Titulo do objetivo",      "fr": "Titre de l'objectif",      "de": "Zieltitel"],
        "smart.area":           ["es": "Area de vida",          "en": "Life area",              "pt": "Area de vida",            "fr": "Domaine de vie",           "de": "Lebensbereich"],

        // Project labels
        "project.name":        ["es": "Nombre",              "en": "Name",               "pt": "Nome",              "fr": "Nom",               "de": "Name"],
        "project.description": ["es": "Descripcion",         "en": "Description",        "pt": "Descricao",         "fr": "Description",       "de": "Beschreibung"],
        "project.priority":    ["es": "Prioridad",           "en": "Priority",           "pt": "Prioridade",        "fr": "Priorite",          "de": "Prioritat"],
        "project.start":       ["es": "Fecha inicio",        "en": "Start date",         "pt": "Data de inicio",    "fr": "Date de debut",     "de": "Startdatum"],
        "project.end":         ["es": "Fecha fin",           "en": "End date",           "pt": "Data de fim",       "fr": "Date de fin",       "de": "Enddatum"],
        "project.objective":   ["es": "Objetivo vinculado",  "en": "Linked objective",   "pt": "Objetivo vinculado","fr": "Objectif lie",      "de": "Verknupftes Ziel"],
        "project.status":      ["es": "Estado",              "en": "Status",             "pt": "Status",            "fr": "Statut",            "de": "Status"],

        // Filters
        "filter.all":                      ["es": "Todos",                                  "en": "All",                                  "pt": "Todos",                                 "fr": "Tous",                                  "de": "Alle"],
        "projects.no_objective_projects":  ["es": "No hay proyectos para este objetivo",    "en": "No projects for this objective",        "pt": "Sem projetos para este objetivo",        "fr": "Pas de projets pour cet objectif",      "de": "Keine Projekte für dieses Ziel"],
        "common.create":                   ["es": "Crear",                                  "en": "Create",                               "pt": "Criar",                                 "fr": "Créer",                                 "de": "Erstellen"],
        "common.cancel":                   ["es": "Cancelar",                               "en": "Cancel",                               "pt": "Cancelar",                              "fr": "Annuler",                               "de": "Abbrechen"],

        // Task labels
        "task.title_field":     ["es": "Titulo",                "en": "Title",                "pt": "Titulo",              "fr": "Titre",                "de": "Titel"],
        "task.project":         ["es": "Proyecto",              "en": "Project",              "pt": "Projeto",             "fr": "Projet",               "de": "Projekt"],
        "task.delegate_toggle": ["es": "Delegar a alguien",     "en": "Delegate to someone",  "pt": "Delegar para alguem", "fr": "Deleguer a quelqu'un", "de": "An jemanden delegieren"],
        "task.assignee":        ["es": "Responsable",           "en": "Assignee",             "pt": "Responsavel",         "fr": "Responsable",          "de": "Zustandig"],
        "task.notes":           ["es": "Notas de delegacion",   "en": "Delegation notes",     "pt": "Notas de delegacao",  "fr": "Notes de delegation",  "de": "Delegationsnotizen"],
        "task.contacts":        ["es": "Asociar contactos",     "en": "Associate contacts",   "pt": "Associar contatos",   "fr": "Associer contacts",    "de": "Kontakte zuordnen"],
        "task.select_contact":  ["es": "Seleccionar contacto",  "en": "Select contact",       "pt": "Selecionar contato",  "fr": "Selectionner contact", "de": "Kontakt auswahlen"],
        "task.no_priority":     ["es": "Sin prioridad = va al Inbox", "en": "No priority = goes to Inbox", "pt": "Sem prioridade = vai para Inbox", "fr": "Sans priorite = va dans Inbox", "de": "Keine Prioritat = geht in Inbox"],
        "task.delegate_option_contact": ["es": "De mis contactos",           "en": "From my contacts",        "pt": "Dos meus contatos",           "fr": "De mes contacts",             "de": "Aus meinen Kontakten"],
        "task.delegate_option_manual":  ["es": "Escribir nombre",            "en": "Write name",              "pt": "Escrever nome",               "fr": "Ecrire le nom",               "de": "Name eingeben"],
        "task.save_as_contact":         ["es": "Guardar como nuevo contacto", "en": "Save as new contact",    "pt": "Salvar como novo contato",    "fr": "Enregistrer comme nouveau contact", "de": "Als neuen Kontakt speichern"],
        "task.from_meeting":            ["es": "De que reunion surgio?",      "en": "From which meeting did it arise?", "pt": "De qual reuniao surgiu?", "fr": "De quelle reunion est-il ne?", "de": "Aus welchem Meeting entstand es?"],
        "task.known_participants":      ["es": "Participantes conocidos",     "en": "Known participants",      "pt": "Participantes conhecidos",    "fr": "Participants connus",          "de": "Bekannte Teilnehmer"],
        "task.no_meetings_today":       ["es": "No hay reuniones hoy",        "en": "No meetings today",       "pt": "Sem reunioes hoje",           "fr": "Pas de reunions aujourd'hui",  "de": "Keine Besprechungen heute"],

        // Contact labels
        "contact.name":         ["es": "Nombre",             "en": "Name",              "pt": "Nome",             "fr": "Nom",              "de": "Name"],
        "contact.email":        ["es": "Correo electronico", "en": "Email",             "pt": "E-mail",           "fr": "E-mail",           "de": "E-Mail"],
        "contact.phone":        ["es": "Telefono",           "en": "Phone",             "pt": "Telefone",         "fr": "Telephone",        "de": "Telefon"],
        "contact.company":      ["es": "Empresa",            "en": "Company",           "pt": "Empresa",          "fr": "Entreprise",       "de": "Unternehmen"],
        "contact.role":         ["es": "Cargo",              "en": "Role",              "pt": "Cargo",            "fr": "Poste",            "de": "Position"],
        "contact.operational":  ["es": "Operativa",          "en": "Operational",       "pt": "Operacional",      "fr": "Operationnel",     "de": "Operativ"],
        "contact.personal_net": ["es": "Personal",           "en": "Personal",          "pt": "Pessoal",          "fr": "Personnel",        "de": "Personlich"],
        "contact.strategic":    ["es": "Estrategica",        "en": "Strategic",         "pt": "Estrategica",      "fr": "Strategique",      "de": "Strategisch"],
        "contact.unclassified": ["es": "Sin clasificar",     "en": "Unclassified",      "pt": "Sem classificacao","fr": "Non classe",       "de": "Nicht klassifiziert"],
        "contact.influence_high":   ["es": "Alto",   "en": "High",   "pt": "Alto",   "fr": "Eleve",  "de": "Hoch"],
        "contact.influence_medium": ["es": "Medio",  "en": "Medium", "pt": "Medio",  "fr": "Moyen",  "de": "Mittel"],
        "contact.influence_low":    ["es": "Bajo",   "en": "Low",    "pt": "Baixo",  "fr": "Faible", "de": "Niedrig"],
        "contact.filter.all":       ["es": "Todos",  "en": "All",    "pt": "Todos",  "fr": "Tous",   "de": "Alle"],

        // Email analysis
        "emails.analyze_btn":          ["es": "Analizar correos con IA",                              "en": "Analyze emails with AI",                        "pt": "Analisar e-mails com IA",                          "fr": "Analyser les e-mails avec IA",                        "de": "E-Mails mit KI analysieren"],
        "emails.import_gmail":         ["es": "Importar desde Gmail",                                 "en": "Import from Gmail",                             "pt": "Importar do Gmail",                                "fr": "Importer depuis Gmail",                               "de": "Von Gmail importieren"],
        "emails.import_file":          ["es": "Importar archivo .mbox/.eml",                          "en": "Import .mbox/.eml file",                        "pt": "Importar arquivo .mbox/.eml",                      "fr": "Importer fichier .mbox/.eml",                         "de": ".mbox/.eml Datei importieren"],
        "emails.no_gmail_connected":   ["es": "Conecta tu cuenta de Google para importar correos",    "en": "Connect your Google account to import emails",  "pt": "Conecte sua conta Google para importar e-mails",   "fr": "Connectez votre compte Google pour importer des e-mails", "de": "Verbinden Sie Ihr Google-Konto, um E-Mails zu importieren"],
        "emails.unread_only":          ["es": "Solo no leídos",                                       "en": "Unread only",                                   "pt": "Apenas não lidos",                                 "fr": "Non lus seulement",                                   "de": "Nur ungelesene"],
        "emails.exclude_newsletters":  ["es": "Excluir newsletters",                                  "en": "Exclude newsletters",                           "pt": "Excluir newsletters",                              "fr": "Exclure les newsletters",                             "de": "Newsletter ausschließen"],
        "emails.attachments_only":     ["es": "Solo con adjuntos",                                    "en": "With attachments only",                         "pt": "Apenas com anexos",                                "fr": "Avec pièces jointes uniquement",                      "de": "Nur mit Anhängen"],
        "emails.connected_account":    ["es": "Cuenta conectada",                                     "en": "Connected account",                             "pt": "Conta conectada",                                  "fr": "Compte connecté",                                     "de": "Verbundenes Konto"],
        "emails.period":               ["es": "Período",                                              "en": "Period",                                        "pt": "Período",                                          "fr": "Période",                                             "de": "Zeitraum"],
        "emails.filters":              ["es": "Filtros",                                               "en": "Filters",                                       "pt": "Filtros",                                          "fr": "Filtres",                                             "de": "Filter"],
        "emails.go_settings":          ["es": "Ir a Configuraciones",                                 "en": "Go to Settings",                                "pt": "Ir para Configurações",                            "fr": "Aller aux Paramètres",                                "de": "Zu Einstellungen gehen"],
        "emails.import_btn":           ["es": "Importar correos de Gmail",                            "en": "Import emails from Gmail",                      "pt": "Importar e-mails do Gmail",                        "fr": "Importer les e-mails de Gmail",                       "de": "E-Mails von Gmail importieren"],
        "emails.importing":            ["es": "Importando...",                                        "en": "Importing...",                                  "pt": "Importando...",                                    "fr": "Importation...",                                      "de": "Importiere..."],
        "emails.import_success":       ["es": "{count} correos importados",                           "en": "{count} emails imported",                       "pt": "{count} e-mails importados",                       "fr": "{count} e-mails importés",                            "de": "{count} E-Mails importiert"],
        "emails.import_skipped":       ["es": "{count} ya existentes (omitidos)",                     "en": "{count} already existing (skipped)",             "pt": "{count} já existentes (ignorados)",                "fr": "{count} déjà existants (ignorés)",                    "de": "{count} bereits vorhanden (übersprungen)"],
        "emails.max_results":          ["es": "Cantidad a importar",      "en": "Amount to import",       "pt": "Quantidade a importar",    "fr": "Quantité à importer",      "de": "Importmenge"],
        "emails.import_result":        ["es": "Resultado",                "en": "Result",                 "pt": "Resultado",                "fr": "Résultat",                 "de": "Ergebnis"],
        "emails.total_found":          ["es": "Total encontrados",        "en": "Total found",            "pt": "Total encontrados",        "fr": "Total trouvés",            "de": "Gesamt gefunden"],
        "emails.skip.duplicate":       ["es": "duplicados",               "en": "duplicates",             "pt": "duplicados",               "fr": "doublons",                 "de": "Duplikate"],
        "emails.force_reimport":       ["es": "Forzar reimportación (sobreescribir)", "en": "Force reimport (overwrite)", "pt": "Forçar reimportação (sobrescrever)", "fr": "Forcer la réimportation (écraser)", "de": "Reimport erzwingen (überschreiben)"],
        "emails.view_imported":        ["es": "Ver correos importados ({count})",     "en": "View imported emails ({count})", "pt": "Ver e-mails importados ({count})", "fr": "Voir les e-mails importés ({count})", "de": "Importierte E-Mails anzeigen ({count})"],
        "emails.imported_title":       ["es": "Correos importados",    "en": "Imported emails",        "pt": "E-mails importados",       "fr": "E-mails importés",         "de": "Importierte E-Mails"],
        "emails.no_imported":          ["es": "No hay correos importados", "en": "No imported emails",  "pt": "Sem e-mails importados",   "fr": "Pas d'e-mails importés",   "de": "Keine importierten E-Mails"],
        "emails.search_placeholder":   ["es": "Buscar por asunto",    "en": "Search by subject",      "pt": "Buscar por assunto",       "fr": "Rechercher par sujet",     "de": "Nach Betreff suchen"],
        "common.done":                 ["es": "Listo",                "en": "Done",                   "pt": "Pronto",                   "fr": "Terminé",                  "de": "Fertig"],
        "common.delete":               ["es": "Eliminar",             "en": "Delete",                 "pt": "Excluir",                  "fr": "Supprimer",                "de": "Löschen"],
        "emails.delete_gmail_only":    ["es": "Eliminar correos de Gmail",  "en": "Delete Gmail emails",  "pt": "Excluir e-mails do Gmail",  "fr": "Supprimer e-mails Gmail",  "de": "Gmail-E-Mails löschen"],
        "emails.delete_gmail_confirm": ["es": "¿Eliminar todos los correos importados desde Gmail? Los correos de archivo no se verán afectados.", "en": "Delete all emails imported from Gmail? File-imported emails will not be affected.", "pt": "Excluir todos os e-mails importados do Gmail? E-mails de arquivo não serão afetados.", "fr": "Supprimer tous les e-mails importés de Gmail? Les e-mails de fichier ne seront pas affectés.", "de": "Alle von Gmail importierten E-Mails löschen? Datei-importierte E-Mails werden nicht betroffen."],
        "emails.mark_read":            ["es": "Marcar como leído",    "en": "Mark as read",           "pt": "Marcar como lido",         "fr": "Marquer comme lu",         "de": "Als gelesen markieren"],
        "emails.mark_all_read":        ["es": "Marcar todos como leídos",             "en": "Mark all as read",                  "pt": "Marcar todos como lidos",           "fr": "Tout marquer comme lu",             "de": "Alle als gelesen markieren"],
        "emails.mark_category_read":   ["es": "Marcar {category} como leídos",        "en": "Mark {category} as read",           "pt": "Marcar {category} como lidos",      "fr": "Marquer {category} comme lu",       "de": "{category} als gelesen markieren"],
        "emails.source_file":          ["es": "Archivo",              "en": "File",                   "pt": "Arquivo",                  "fr": "Fichier",                  "de": "Datei"],
        "emails.gmail_sync_note":      ["es": "Al marcar correos como leídos aquí, también se marcarán en tu cuenta de Gmail.", "en": "When marking emails as read here, they will also be marked in your Gmail account.", "pt": "Ao marcar e-mails como lidos aqui, eles também serão marcados em sua conta Gmail.", "fr": "En marquant les e-mails comme lus ici, ils seront également marqués dans votre compte Gmail.", "de": "Wenn Sie E-Mails hier als gelesen markieren, werden sie auch in Ihrem Gmail-Konto markiert."],

        // Gmail errors
        "gmail.error.reconnect_title":     ["es": "Reconexión necesaria",                                                          "en": "Reconnection needed",                                                                    "pt": "Reconexão necessária",                                                                  "fr": "Reconnexion nécessaire",                                                                    "de": "Erneute Verbindung erforderlich"],
        "gmail.error.reconnect_msg":       ["es": "Al conectar tu cuenta de Google no se incluyo el permiso de Gmail. Para solucionarlo:\n1. Ve a Configuraciones → Google Calendar\n2. Desconecta tu cuenta\n3. Vuelve a conectarla\n4. Acepta TODOS los permisos incluyendo Gmail\nSin este permiso no es posible importar correos.", "en": "When connecting your Google account, Gmail permission was not included. To fix this:\n1. Go to Settings → Google Calendar\n2. Disconnect your account\n3. Reconnect it\n4. Accept ALL permissions including Gmail\nWithout this permission emails cannot be imported.", "pt": "Ao conectar sua conta Google, a permissao do Gmail nao foi incluida. Para corrigir:\n1. Va em Configuracoes → Google Calendar\n2. Desconecte sua conta\n3. Reconecte-a\n4. Aceite TODAS as permissoes incluindo Gmail", "fr": "Lors de la connexion de votre compte Google, la permission Gmail n'a pas ete incluse. Pour corriger:\n1. Allez dans Parametres → Google Calendar\n2. Deconnectez votre compte\n3. Reconnectez-le\n4. Acceptez TOUTES les permissions incluant Gmail", "de": "Beim Verbinden Ihres Google-Kontos wurde die Gmail-Berechtigung nicht eingeschlossen. So beheben:\n1. Gehen Sie zu Einstellungen → Google Calendar\n2. Trennen Sie Ihr Konto\n3. Verbinden Sie es erneut\n4. Akzeptieren Sie ALLE Berechtigungen inkl. Gmail"],
        "gmail.error.go_settings":         ["es": "Ir a Configuraciones",          "en": "Go to Settings",              "pt": "Ir para Configurações",          "fr": "Aller aux Paramètres",            "de": "Zu Einstellungen gehen"],
        "gmail.error.retry":               ["es": "Reintentar",                    "en": "Retry",                       "pt": "Tentar novamente",               "fr": "Réessayer",                       "de": "Erneut versuchen"],
        "gmail.error.import_error_title":  ["es": "Error al importar",             "en": "Import error",                "pt": "Erro ao importar",               "fr": "Erreur d'importation",            "de": "Importfehler"],
        "gmail.error.unavailable_msg":     ["es": "El servicio de Gmail no está disponible temporalmente. Intenta de nuevo en unos minutos.", "en": "Gmail service is temporarily unavailable. Try again in a few minutes.", "pt": "O serviço do Gmail está temporariamente indisponível. Tente novamente em alguns minutos.", "fr": "Le service Gmail est temporairement indisponible. Réessayez dans quelques minutes.", "de": "Der Gmail-Dienst ist vorübergehend nicht verfügbar. Versuchen Sie es in einigen Minuten erneut."],
        "gmail.error.generic_msg":         ["es": "No se pudieron importar los correos. Verifica tu conexión e intenta de nuevo.", "en": "Could not import emails. Check your connection and try again.", "pt": "Não foi possível importar os e-mails. Verifique sua conexão e tente novamente.", "fr": "Impossible d'importer les e-mails. Vérifiez votre connexion et réessayez.", "de": "E-Mails konnten nicht importiert werden. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut."],

        // Task source tracking
        "source.origin":          ["es": "Origen",                          "en": "Origin",            "pt": "Origem",              "fr": "Origine",              "de": "Ursprung"],
        "source.commitment":      ["es": "Como surgio este compromiso?",    "en": "How did this arise?","pt": "Como surgiu?",        "fr": "Comment est-ce ne?",   "de": "Wie entstand das?"],
        "source.reunion":         ["es": "Reunion",          "en": "Meeting",          "pt": "Reuniao",         "fr": "Reunion",         "de": "Besprechung"],
        "source.correo":          ["es": "Correo",           "en": "Email",            "pt": "E-mail",          "fr": "E-mail",          "de": "E-Mail"],
        "source.llamada":         ["es": "Llamada",          "en": "Call",             "pt": "Ligacao",         "fr": "Appel",           "de": "Anruf"],
        "source.mensaje":         ["es": "Mensaje",          "en": "Message",          "pt": "Mensagem",        "fr": "Message",         "de": "Nachricht"],
        "source.decision_propia": ["es": "Decision propia",  "en": "Own decision",     "pt": "Decisao propria", "fr": "Decision personnelle","de": "Eigene Entscheidung"],
        "source.solicitud":       ["es": "Solicitud",        "en": "Request",          "pt": "Solicitacao",     "fr": "Demande",         "de": "Anfrage"],
        "source.seguimiento":     ["es": "Seguimiento",      "en": "Follow-up",        "pt": "Acompanhamento",  "fr": "Suivi",           "de": "Nachverfolgung"],
        "source.otro":            ["es": "Otro",             "en": "Other",            "pt": "Outro",           "fr": "Autre",           "de": "Anderes"],
        "source.date":            ["es": "Fecha del origen", "en": "Source date",       "pt": "Data de origem",  "fr": "Date d'origine",  "de": "Ursprungsdatum"],
        "source.notes_placeholder":["es":"Notas del origen (opcional)", "en": "Source notes (optional)", "pt": "Notas de origem (opcional)", "fr": "Notes d'origine (facultatif)", "de": "Ursprungsnotizen (optional)"],
        "source.select_meeting":  ["es": "Seleccionar reunion","en": "Select meeting",  "pt": "Selecionar reuniao","fr": "Selectionner reunion","de": "Besprechung auswahlen"],

        // Trash
        "trash.title":          ["es": "Basurero",           "en": "Trash",              "pt": "Lixeira",            "fr": "Corbeille",           "de": "Papierkorb"],
        "trash.tasks":          ["es": "Tareas",             "en": "Tasks",              "pt": "Tarefas",            "fr": "Taches",              "de": "Aufgaben"],
        "trash.projects":       ["es": "Proyectos",          "en": "Projects",           "pt": "Projetos",           "fr": "Projets",             "de": "Projekte"],
        "trash.objectives":     ["es": "Objetivos",          "en": "Objectives",         "pt": "Objetivos",          "fr": "Objectifs",           "de": "Ziele"],
        "trash.restore":        ["es": "Restaurar",          "en": "Restore",            "pt": "Restaurar",          "fr": "Restaurer",           "de": "Wiederherstellen"],
        "trash.empty":          ["es": "Vaciar basurero",    "en": "Empty trash",        "pt": "Esvaziar lixeira",   "fr": "Vider la corbeille",  "de": "Papierkorb leeren"],
        "trash.empty_confirm":  ["es": "Eliminar permanentemente todos los elementos?", "en": "Permanently delete all items?", "pt": "Excluir permanentemente todos os itens?", "fr": "Supprimer definitivement tous les elements?", "de": "Alle Elemente dauerhaft loschen?"],
        "trash.deleted_on":     ["es": "Eliminado el",       "en": "Deleted on",         "pt": "Excluido em",        "fr": "Supprime le",         "de": "Geloscht am"],
        "trash.auto_delete":    ["es": "Los elementos se eliminan automaticamente despues de 30 dias", "en": "Items are automatically deleted after 30 days", "pt": "Os itens sao excluidos automaticamente apos 30 dias", "fr": "Les elements sont automatiquement supprimes apres 30 jours", "de": "Elemente werden nach 30 Tagen automatisch geloscht"],
        "trash.deleted":        ["es": "Eliminadas",         "en": "Deleted",            "pt": "Excluidas",          "fr": "Supprimees",          "de": "Geloscht"],
        "trash.completed":      ["es": "Completadas",        "en": "Completed",          "pt": "Concluidas",         "fr": "Terminees",           "de": "Abgeschlossen"],
        "trash.reactivate":     ["es": "Reactivar",          "en": "Reactivate",         "pt": "Reativar",           "fr": "Reactiver",           "de": "Reaktivieren"],
        "trash.completed_on":   ["es": "Completado el",      "en": "Completed on",       "pt": "Concluido em",       "fr": "Termine le",          "de": "Abgeschlossen am"],

        // Assistant
        "assistant.thinking":      ["es": "Pensando",                    "en": "Thinking",          "pt": "Pensando",             "fr": "En train de reflechir", "de": "Nachdenken"],
        "assistant.mic_off":       ["es": "Microfono desactivado",       "en": "Microphone off",    "pt": "Microfone desativado",  "fr": "Microphone desactive",  "de": "Mikrofon aus"],
        "assistant.no_connection": ["es": "Sin conexion. Reintentar?",   "en": "No connection. Retry?", "pt": "Sem conexao. Tentar novamente?", "fr": "Pas de connexion. Reessayer?", "de": "Keine Verbindung. Wiederholen?"],
        "assistant.retry":         ["es": "Reintentar",                  "en": "Retry",             "pt": "Tentar novamente",      "fr": "Reessayer",             "de": "Wiederholen"],
    ]
}
