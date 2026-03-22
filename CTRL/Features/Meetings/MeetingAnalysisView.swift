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
                                Task { await loadAnalysis() }
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
                        Task { await loadAnalysis() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task { await loadUsage() }
        .onChange(of: selectedPeriod) { newValue in
            if newValue != "custom" {
                Task { await loadAnalysis() }
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
        } else if interactionsRemaining < 20 && interactionsRemaining > 0 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Pocas interacciones disponibles (\(interactionsRemaining) restantes)")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(10)
            .background(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        } else if interactionsRemaining > 0 {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                Text("Este analisis usa aproximadamente 1 interaccion de IA (\(interactionsRemaining) restantes)")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func loadUsage() async {
        do {
            usageSummary = try await APIClient.shared.request(.usageSummary)
        } catch { }
    }

    private func loadAnalysis() async {
        guard userPlan != "free" else { return }
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
