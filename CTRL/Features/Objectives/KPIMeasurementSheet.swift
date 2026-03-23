import SwiftUI

struct KPIMeasurementSheet: View {
    let objective: Objective
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var valueText = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(objective.title)
                        .font(.headline)
                    if let kpi = objective.kpiName {
                        Text(kpi)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Valor actual") {
                    TextField("Ingresa el valor medido", text: $valueText)
                        .keyboardType(.decimalPad)
                        .font(.title2)

                    if let target = objective.kpiTarget, let unit = objective.kpiUnit {
                        Text("Meta: \(formatNum(target)) \(unit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let value = Double(valueText), let target = objective.kpiTarget,
                       let baseline = objective.kpiBaseline, baseline != target {
                        let isReduction = target < baseline
                        let raw = isReduction
                            ? ((baseline - value) / (baseline - target)) * 100
                            : ((value - baseline) / (target - baseline)) * 100
                        let pct = Int(max(0, min(100, raw)))
                        let completed = isReduction ? value <= target : value >= target
                        let label = isReduction ? "Reducido" : "Avance"

                        if completed {
                            Label("Meta alcanzada", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("\(label): \(pct)%")
                                .font(.caption)
                                .foregroundStyle(pct >= 70 ? .green : pct >= 30 ? .orange : .red)
                        }
                    }
                }

                Section("Notas (opcional)") {
                    TextField("Contexto de esta medicion...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        Task { await saveMeasurement() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Registrar medicion")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(valueText.isEmpty || isSaving)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationTitle("Registrar KPI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func formatNum(_ n: Double) -> String {
        n == n.rounded() ? String(Int(n)) : String(format: "%.1f", n)
    }

    private func saveMeasurement() async {
        guard let value = Double(valueText) else { return }
        isSaving = true

        let body = UpdateKpiBody(
            kpiCurrent: value,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let _: Objective = try await APIClient.shared.request(
                .objectiveKpi(id: objective.id), method: "PATCH", body: body
            )
            onSave()
            dismiss()
        } catch {
            print("[KPISheet] Save measurement error: \(error)")
        }
        isSaving = false
    }
}
