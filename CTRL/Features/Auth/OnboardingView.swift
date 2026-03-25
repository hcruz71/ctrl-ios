import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var showSheet = false
    @State private var sheetType: SheetType?

    private enum SheetType: Identifiable {
        case objective, calendar, ics, contacts, task, assistant, schedule
        var id: Int { hashValue }
    }

    private let totalSteps = 8

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<totalSteps, id: \.self) { i in
                            Circle()
                                .fill(i <= step ? Color.ctrlPurple : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Spacer()
                    if step < totalSteps - 1 {
                        Button(lang.t("onboarding.skip")) {
                            withAnimation { step = totalSteps - 1 }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()

                // Content
                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    objectiveStep.tag(1)
                    calendarStep.tag(2)
                    contactsStep.tag(3)
                    taskStep.tag(4)
                    assistantStep.tag(5)
                    scheduleStep.tag(6)
                    finishStep.tag(7)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
            }
        }
        .sheet(item: $sheetType) { type in
            sheetContent(type)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        stepView(
            icon: nil,
            title: lang.t("onboarding.welcome"),
            subtitle: "Control  ·  Tareas  ·  Reuniones  ·  Liderazgo",
            description: lang.t("onboarding.subtitle"),
            primaryLabel: lang.t("onboarding.start"),
            primaryAction: { withAnimation { step = 1 } }
        ) {
            Image("CTRLLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text("CTRL")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(Color.ctrlPurple)
        }
    }

    private var objectiveStep: some View {
        stepView(
            icon: "target",
            title: lang.t("onboarding.step1.title"),
            subtitle: nil,
            description: "La metodologia SMART asegura que tu objetivo sea Especifico, Medible, Alcanzable, Relevante y con Tiempo definido.",
            primaryLabel: "Crear mi primer objetivo",
            primaryAction: { sheetType = .objective },
            secondaryLabel: lang.t("onboarding.later"),
            secondaryAction: { withAnimation { step = 2 } }
        )
    }

    private var calendarStep: some View {
        stepView(
            icon: "calendar",
            title: lang.t("onboarding.step2.title"),
            subtitle: nil,
            description: "Importa tu calendario corporativo para ver todas tus reuniones, identificar cuales puedes delegar y llegar preparado.",
            primaryLabel: "Conectar Google Calendar",
            primaryAction: { sheetType = .calendar },
            secondaryLabel: lang.t("onboarding.later"),
            secondaryAction: { withAnimation { step = 3 } }
        )
    }

    private var contactsStep: some View {
        stepView(
            icon: "person.2.fill",
            title: lang.t("onboarding.step3.title"),
            subtitle: nil,
            description: "Los ejecutivos exitosos cultivan 3 tipos de red: Operativa (dia a dia), Personal (mentores) y Estrategica (oportunidades futuras).",
            primaryLabel: "Agregar contactos",
            primaryAction: { sheetType = .contacts },
            secondaryLabel: lang.t("onboarding.later"),
            secondaryAction: { withAnimation { step = 4 } }
        )
    }

    private var taskStep: some View {
        stepView(
            icon: "checkmark.circle.fill",
            title: "Organiza tu dia con A/B/C",
            subtitle: nil,
            description: "A = Urgente e Importante (max 3/dia)\nB = Importante, no urgente (estrategicas)\nC = Urgente pero delegable\n\nCaptura todo lo pendiente y asignale prioridad.",
            primaryLabel: "Capturar mis pendientes",
            primaryAction: { sheetType = .task },
            secondaryLabel: lang.t("onboarding.later"),
            secondaryAction: { withAnimation { step = 5 } }
        )
    }

    private var assistantStep: some View {
        stepView(
            icon: "sparkles",
            title: "Tu Chief of Staff con IA",
            subtitle: nil,
            description: "El asistente CTRL conoce tus objetivos, reuniones y tareas. Puedes hablarle:\n\n'Dame mi resumen del dia'\n'Crea una tarea urgente'\n'Como voy con mis objetivos?'",
            primaryLabel: "Configurar mi asistente",
            primaryAction: { sheetType = .assistant },
            secondaryLabel: "Usar configuracion default",
            secondaryAction: { withAnimation { step = 6 } }
        )
    }

    private var scheduleStep: some View {
        stepView(
            icon: "clock.fill",
            title: "CTRL respeta tu tiempo",
            subtitle: nil,
            description: "Configura tus dias laborables y horarios. En modo descanso, el asistente NO te molestara con pendientes. En vacaciones, genera documentos de entrega automaticamente.",
            primaryLabel: "Configurar horario",
            primaryAction: { sheetType = .schedule },
            secondaryLabel: "Usar defaults (Lun-Vie 8am-6pm)",
            secondaryAction: { withAnimation { step = 7 } }
        )
    }

    private var finishStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Estas listo, \(authManager.currentUser?.name ?? "")!")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("CTRL esta configurado para ayudarte a alcanzar tus objetivos y liderar con claridad.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                tipRow("Revisa tu resumen cada manana")
                tipRow("Procesa tu inbox de tareas diariamente")
                tipRow("Actualiza tus KPIs semanalmente")
                tipRow("Haz la revision semanal cada viernes")
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task {
                    await authManager.completeOnboarding()
                    dismiss()
                }
            } label: {
                Text(lang.t("onboarding.finish"))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Reusable Step

    private func stepView(
        icon: String?,
        title: String,
        subtitle: String?,
        description: String,
        primaryLabel: String,
        primaryAction: @escaping () -> Void,
        secondaryLabel: String? = nil,
        secondaryAction: (() -> Void)? = nil,
        @ViewBuilder header: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(spacing: 20) {
            Spacer()

            header()

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.ctrlPurple)
            }

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: primaryAction) {
                Text(primaryLabel)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            if let secondaryLabel, let secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.ctrlPurple)
                }
            }

            Spacer(minLength: 32)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(_ type: SheetType) -> some View {
        switch type {
        case .objective:
            SMARTObjectiveFormView(vm: ObjectivesViewModel()) {
                sheetType = nil
                withAnimation { step = 2 }
            }
        case .calendar:
            SettingsView()
                .onDisappear { withAnimation { step = 3 } }
        case .ics:
            Text("ICS Import")
                .onDisappear { withAnimation { step = 3 } }
        case .contacts:
            NavigationStack {
                ContactsContentView()
                    .navigationTitle(lang.t("contacts.title"))
            }
            .onDisappear { withAnimation { step = 4 } }
        case .task:
            AddTaskSheetWrapper {
                sheetType = nil
                withAnimation { step = 5 }
            }
        case .assistant:
            ProfileView()
                .onDisappear { withAnimation { step = 6 } }
        case .schedule:
            NavigationStack {
                ScheduleSettingsView()
            }
            .onDisappear { withAnimation { step = 7 } }
        }
    }
}

// Simple wrapper to create a task and dismiss
private struct AddTaskSheetWrapper: View {
    var onDone: () -> Void
    @StateObject private var vm = TasksViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedLevel: String? = "A"
    @State private var startDate = Date()
    @State private var hasStartDate = false
    @State private var endDate = Date()
    @State private var hasEndDate = false
    @State private var isDelegated = false
    @State private var assignee = ""
    @State private var assigneeContactId: UUID?
    @State private var delegationNotes = ""
    @State private var selectedProjectId: UUID?
    @State private var selectedContactIds: Set<UUID> = []
    @State private var sourceType: String?
    @State private var sourceNotes = ""

    var body: some View {
        NavigationStack {
            Form {
                TaskFormView(
                    title: $title,
                    selectedLevel: $selectedLevel,
                    startDate: $startDate,
                    hasStartDate: $hasStartDate,
                    endDate: $endDate,
                    hasEndDate: $hasEndDate,
                    isDelegated: $isDelegated,
                    assignee: $assignee,
                    assigneeContactId: $assigneeContactId,
                    delegationNotes: $delegationNotes,
                    selectedProjectId: $selectedProjectId,
                    selectedContactIds: $selectedContactIds,
                    sourceType: $sourceType,
                    sourceNotes: $sourceNotes
                )
            }
            .navigationTitle("Nueva tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss(); onDone() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"
                        let body = CreateTaskBody(
                            title: title,
                            priorityLevel: selectedLevel,
                            dueDate: hasEndDate ? df.string(from: endDate) : nil,
                            startDate: hasStartDate ? df.string(from: startDate) : nil,
                            inbox: selectedLevel == nil,
                            sourceType: sourceType,
                            sourceNotes: sourceNotes.isEmpty ? nil : sourceNotes
                        )
                        Task {
                            await vm.create(body)
                            dismiss()
                            onDone()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
