import SwiftUI

struct MeetingAnalysisView: View {
    @ObservedObject var vm: MeetingsViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var analysis: MeetingAnalysis?
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var selectedPeriod = "week"
    @State private var expandedRawData = false
    @State private var usageSummary: UsageSummary?

    // Custom date range
    @State private var showCustomDates = false
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEnd = Date()

    // Confirmation alert
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""

    private let periods = [
        ("day", "Hoy"),
        ("week", "Semana"),
        ("month", "Mes"),
    ]

    private var interactionsRemaining: Int {
        usageSummary?.interactionsRemaining ?? 0
    }

    private var userPlan: String {
        authManager.currentUser?.plan ?? "free"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period picker
                    HStack {
                        Picker("Periodo", selection: $selectedPeriod) {
                            ForEach(periods, id: \.0) { p in
                                Text(p.1).tag(p.0)
                            }
                            if showCustomDates {
                                Text("Personalizado").tag("custom")
                            }
                        }
                        .pickerStyle(.segmented)

                        Button {
                            withAnimation { showCustomDates.toggle() }
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundStyle(showCustomDates ? Color.ctrlPurple : .secondary)
                        }
                    }
                    .padding(.horizontal)

                    if showCustomDates {
                        VStack(spacing: 8) {
                            DatePicker("Inicio", selection: $customStart, displayedComponents: .date)
                            DatePicker("Fin", selection: $customEnd, displayedComponents: .date)
                            Button("Analizar periodo") {
                                selectedPeriod = "custom"
                                requestAnalysis()
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.ctrlPurple)
                        }
                        .padding(.horizontal)
                    }

                    // Usage warning banners
                    usageBanner

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Analizando reuniones con IA...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let analysis {
                        // AI Analysis
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Analisis IA", systemImage: "sparkles")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.ctrlPurple)

                            Text(analysis.aiAnalysis)
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                        // Raw data (collapsible)
                        if let raw = analysis.rawData {
                            rawDataSection(raw)
                        }
                    } else if hasLoaded {
                        Text("No se pudo generar el analisis")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Inteligencia de Reuniones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        requestAnalysis()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Analisis con IA", isPresented: $showConfirmation) {
                Button("Analizar") {
                    Task { await executeAnalysis() }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(confirmationMessage)
            }
        }
        .task { await loadUsage() }
        .onChange(of: selectedPeriod) { newValue in
            if newValue != "custom" {
                requestAnalysis()
            }
        }
    }

    // MARK: - Usage Banner

    @ViewBuilder
    private var usageBanner: some View {
        if userPlan == "free" {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Plan Pro requerido")
                        .font(.caption.bold())
                    Text("El analisis con IA requiere plan Pro")
                        .font(.caption2)
                }
                Spacer()
                NavigationLink("Ver planes") {
                    SubscriptionView()
                }
                .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(12)
            .background(.red)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }

    // MARK: - Raw Data Section

    private func rawDataSection(_ raw: MeetingAnalysisRawData) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { expandedRawData.toggle() }
            } label: {
                HStack {
                    Label("Datos", systemImage: "chart.bar")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: expandedRawData ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            if expandedRawData {
                VStack(spacing: 8) {
                    dataRow("Total reuniones", "\(raw.total ?? 0)")
                    dataRow("Horas estimadas", "\(raw.hoursEstimated ?? 0)h")
                    dataRow("Con objetivo", "\(raw.withObjective ?? 0)")
                    dataRow("Sin objetivo", "\(raw.withoutObjective ?? 0)")
                    dataRow("Como organizador", "\(raw.asOrganizer ?? 0)")
                    dataRow("Como participante", "\(raw.asParticipant ?? 0)")
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Confirmation Logic

    private func requestAnalysis() {
        guard userPlan != "free" else { return }

        // Count linked/unlinked from already-loaded meetings
        let allMeetings = vm.todayMeetings + vm.upcomingMeetings
        let total = max(allMeetings.count, 1)
        let linked = allMeetings.filter { $0.projectId != nil }.count
        let unlinked = total - linked

        var msg = ""
        if unlinked > 0 {
            msg += "De tus \(total) reuniones:\n"
            msg += "\(linked) vinculadas a proyectos\n"
            msg += "\(unlinked) sin vincular a ningun proyecto\n\n"
            msg += "Te recomendamos vincularlas a un proyecto antes de analizar para obtener mejores resultados.\n\n"
        } else {
            msg += "Todas tus \(total) reuniones estan vinculadas a proyectos.\n\n"
        }

        msg += "Este analisis usara aproximadamente 3-5 interacciones.\n"
        msg += "Te quedan \(interactionsRemaining) interacciones este mes."

        if interactionsRemaining < 5 {
            msg += "\nAtencion: quedan pocas interacciones."
        }

        confirmationMessage = msg
        showConfirmation = true
    }

    // MARK: - Actions

    private func loadUsage() async {
        usageSummary = try? await APIClient.shared.request(.usageSummary)
    }

    private func executeAnalysis() async {
        isLoading = true
        if selectedPeriod == "custom" {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            analysis = await vm.fetchAnalysis(
                period: "custom",
                startDate: df.string(from: customStart),
                endDate: df.string(from: customEnd)
            )
        } else {
            analysis = await vm.fetchAnalysis(period: selectedPeriod)
        }
        hasLoaded = true
        isLoading = false
        await loadUsage()
    }

    private func dataRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
