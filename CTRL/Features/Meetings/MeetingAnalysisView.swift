import SwiftUI

struct MeetingAnalysisView: View {
    @ObservedObject var vm: MeetingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var analysis: MeetingAnalysis?
    @State private var isLoading = true
    @State private var selectedPeriod = "week"
    @State private var expandedRawData = false

    private let periods = [
        ("day", "Hoy"),
        ("week", "Semana"),
        ("month", "Mes"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Period picker
                    Picker("Periodo", selection: $selectedPeriod) {
                        ForEach(periods, id: \.0) { p in
                            Text(p.1).tag(p.0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

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
                    } else {
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
        .task { await loadAnalysis() }
        .onChange(of: selectedPeriod) { _ in
            Task { await loadAnalysis() }
        }
    }

    private func loadAnalysis() async {
        isLoading = true
        analysis = await vm.fetchAnalysis(period: selectedPeriod)
        isLoading = false
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
