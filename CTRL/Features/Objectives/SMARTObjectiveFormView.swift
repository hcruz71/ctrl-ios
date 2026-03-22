import SwiftUI

struct SMARTObjectiveFormView: View {
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var isSaving = false

    // Step 1 — Basics
    @State private var title = ""
    @State private var area: ObjectiveArea = .laboral
    @State private var horizon = "mes"

    // Step 2 — SMART
    @State private var specific = ""
    @State private var measurable = ""
    @State private var achievable = ""
    @State private var relevant = ""
    @State private var timeBound = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    // Step 3 — KPI
    @State private var hasKpi = false
    @State private var kpiName = ""
    @State private var kpiBaseline = ""
    @State private var kpiTarget = ""
    @State private var kpiUnit = ""
    @State private var kpiFrequency = "mensual"
    @State private var completionCriteria = ""

    private let horizons = ["semana", "mes", "trimestre", "ano"]
    private let frequencies = ["diaria", "semanal", "mensual", "trimestral"]

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                step1Basics.tag(0)
                step2SMART.tag(1)
                step3KPI.tag(2)
                step4Summary.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if step > 0 {
                            Button("Anterior") { step -= 1 }
                        }
                        Spacer()
                        // Progress dots
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(i == step ? Color.ctrlPurple : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        Spacer()
                        if step < 3 {
                            Button("Siguiente") { step += 1 }
                                .disabled(step == 0 && title.isEmpty)
                        }
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Informacion basica"
        case 1: return "Metodologia SMART"
        case 2: return "KPI de medicion"
        case 3: return "Resumen"
        default: return ""
        }
    }

    // MARK: - Step 1

    private var step1Basics: some View {
        Form {
            Section("Titulo del objetivo") {
                TextField("Ej: Reducir vulnerabilidades criticas", text: $title)
            }

            Section("Area de vida") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(ObjectiveArea.allCases) { a in
                        Button {
                            area = a
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: a.icon)
                                    .font(.title3)
                                Text(a.label)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(area == a ? Color.ctrlPurple.opacity(0.15) : Color(.systemGray6))
                            .foregroundStyle(area == a ? Color.ctrlPurple : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Horizonte") {
                Picker("Horizonte", selection: $horizon) {
                    ForEach(horizons, id: \.self) { h in
                        Text(h.capitalized).tag(h)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Step 2

    private var step2SMART: some View {
        Form {
            Section {
                smartField(
                    letter: "S", name: "Especifico",
                    placeholder: "Que exactamente quieres lograr?",
                    text: $specific
                )
            } header: {
                Text("S — Especifico")
            }

            Section {
                smartField(
                    letter: "M", name: "Medible",
                    placeholder: "Como sabras que lo lograste?",
                    text: $measurable
                )
            } header: {
                Text("M — Medible")
            }

            Section {
                smartField(
                    letter: "A", name: "Alcanzable",
                    placeholder: "Por que puedes lograrlo?",
                    text: $achievable
                )
            } header: {
                Text("A — Alcanzable")
            }

            Section {
                smartField(
                    letter: "R", name: "Relevante",
                    placeholder: "Por que es importante ahora?",
                    text: $relevant
                )
            } header: {
                Text("R — Relevante")
            }

            Section {
                DatePicker("Fecha limite", selection: $timeBound, displayedComponents: .date)
            } header: {
                Text("T — Tiempo definido")
            }
        }
    }

    private func smartField(letter: String, name: String, placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(2...4)
    }

    // MARK: - Step 3

    private var step3KPI: some View {
        Form {
            Section {
                Toggle("Definir KPI de medicion", isOn: $hasKpi)
            }

            if hasKpi {
                Section("Indicador") {
                    TextField("Nombre del KPI", text: $kpiName)
                    HStack {
                        TextField("Valor inicial", text: $kpiBaseline)
                            .keyboardType(.decimalPad)
                        TextField("Meta", text: $kpiTarget)
                            .keyboardType(.decimalPad)
                    }
                    TextField("Unidad (%, MXN, dias...)", text: $kpiUnit)
                }

                Section("Frecuencia de medicion") {
                    Picker("Frecuencia", selection: $kpiFrequency) {
                        ForEach(frequencies, id: \.self) { f in
                            Text(f.capitalized).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Criterio de cumplimiento") {
                    TextField("Cuando se considera cumplido?", text: $completionCriteria, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
        }
    }

    // MARK: - Step 4

    private var step4Summary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: area.icon)
                        .font(.title2)
                        .foregroundStyle(Color.ctrlPurple)
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                        Text("\(area.label) — \(horizon.capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // SMART summary
                if !specific.isEmpty || !measurable.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SMART")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        if !specific.isEmpty { summaryRow("S", specific) }
                        if !measurable.isEmpty { summaryRow("M", measurable) }
                        if !achievable.isEmpty { summaryRow("A", achievable) }
                        if !relevant.isEmpty { summaryRow("R", relevant) }
                        summaryRow("T", formatDate(timeBound))
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // KPI summary
                if hasKpi && !kpiName.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("KPI")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text("\(kpiName): \(kpiBaseline) -> \(kpiTarget) \(kpiUnit)")
                            .font(.subheadline)
                        Text("Frecuencia: \(kpiFrequency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Create button
                Button {
                    Task { await createObjective() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        }
                        Text("Crear objetivo")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(title.isEmpty ? Color.gray : Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.isEmpty || isSaving)
            }
            .padding()
        }
    }

    private func summaryRow(_ letter: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(letter)
                .font(.caption.bold())
                .foregroundStyle(Color.ctrlPurple)
                .frame(width: 16)
            Text(text)
                .font(.caption)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    // MARK: - Create

    private func createObjective() async {
        isSaving = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let body = CreateObjectiveBody(
            title: title,
            area: area.rawValue,
            horizon: horizon,
            smartSpecific: specific.isEmpty ? nil : specific,
            smartMeasurable: measurable.isEmpty ? nil : measurable,
            smartAchievable: achievable.isEmpty ? nil : achievable,
            smartRelevant: relevant.isEmpty ? nil : relevant,
            smartTimeBound: df.string(from: timeBound),
            kpiName: hasKpi && !kpiName.isEmpty ? kpiName : nil,
            kpiTarget: hasKpi ? Double(kpiTarget) : nil,
            kpiCurrent: hasKpi ? Double(kpiBaseline) : nil,
            kpiUnit: hasKpi && !kpiUnit.isEmpty ? kpiUnit : nil,
            kpiBaseline: hasKpi ? Double(kpiBaseline) : nil,
            kpiFrequency: hasKpi ? kpiFrequency : nil,
            completionCriteria: completionCriteria.isEmpty ? nil : completionCriteria
        )

        do {
            let _: Objective = try await APIClient.shared.request(.objectives, body: body)
            onSave()
            dismiss()
        } catch {
            print("[SMARTForm] Create objective error: \(error)")
        }
        isSaving = false
    }
}
