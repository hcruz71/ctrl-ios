import SwiftUI

struct ObjectivesView: View {
    @EnvironmentObject var lang: LanguageManager
    @StateObject private var vm = ObjectivesViewModel()
    @State private var showingAdd = false
    @State private var selectedArea = "all"
    @State private var selectedStatus = "activo"
    @State private var measureObjective: Objective?
    @State private var objectiveToEdit: Objective?
    @State private var showingTrash = false

    private var filteredObjectives: [Objective] {
        var list = vm.objectives
        if selectedArea != "all" {
            list = list.filter { $0.area == selectedArea }
        }
        if selectedStatus != "all" {
            list = list.filter { ($0.status ?? "activo") == selectedStatus }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Area filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        areaTab("all", "Todos", "📋")
                        ForEach(ObjectiveArea.allCases) { a in
                            areaTab(a.rawValue, a.label, a.emoji)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Status filter
                Picker("Status", selection: $selectedStatus) {
                    Text(lang.t("objectives.status.active")).tag("activo")
                    Text(lang.t("objectives.status.completed")).tag("completado")
                    Text(lang.t("objectives.status.paused")).tag("pausado")
                    Text(lang.t("objectives.all")).tag("all")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Content
                if vm.isLoading && vm.objectives.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredObjectives.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(lang.t("objectives.empty"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredObjectives) { objective in
                            ObjectiveSmartRow(objective: objective) {
                                measureObjective = objective
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    objectiveToEdit = objective
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await vm.delete(id: objective.id) }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchObjectives() }
                }
            }
            .navigationTitle(lang.t("objectives.title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingTrash = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingTrash) {
                NavigationStack {
                    TrashView(initialTab: "objectives")
                }
            }
            .sheet(isPresented: $showingAdd) {
                SMARTObjectiveFormView(vm: vm) {
                    showingAdd = false
                    Task { await vm.fetchObjectives() }
                }
            }
            .sheet(item: $objectiveToEdit) { objective in
                SMARTObjectiveFormView(vm: vm, objectiveToEdit: objective) {
                    objectiveToEdit = nil
                    Task { await vm.fetchObjectives() }
                }
            }
            .sheet(item: $measureObjective) { obj in
                KPIMeasurementSheet(objective: obj) {
                    measureObjective = nil
                    Task { await vm.fetchObjectives() }
                }
            }
            .task { await vm.fetchObjectives() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private func areaTab(_ value: String, _ label: String, _ emoji: String) -> some View {
        Button {
            withAnimation { selectedArea = value }
        } label: {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selectedArea == value ? Color.ctrlPurple : Color(.systemGray5))
            .foregroundStyle(selectedArea == value ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Objective Row with SMART/KPI

private struct ObjectiveSmartRow: View {
    let objective: Objective
    var onMeasure: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(objective.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()

                // Status badge
                if let status = objective.status, status != "activo" {
                    Text(status.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(status).opacity(0.15))
                        .foregroundStyle(statusColor(status))
                        .clipShape(Capsule())
                }
            }

            // Area + horizon
            HStack(spacing: 8) {
                if let area = objective.area,
                   let areaEnum = ObjectiveArea(rawValue: area) {
                    HStack(spacing: 3) {
                        Text(areaEnum.emoji)
                            .font(.caption)
                        Text(areaEnum.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let horizon = objective.horizon {
                    Text(horizon.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Progress bar
            let pct = objective.effectiveProgress
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor(pct))
                            .frame(width: max(0, geo.size.width * min(1, CGFloat(pct) / 100)))
                    }
                }
                .frame(height: 6)

                Text("\(pct)%")
                    .font(.caption.bold())
                    .foregroundStyle(progressColor(pct))
                    .frame(width: 36, alignment: .trailing)
            }

            // KPI display
            if let kpiDisplay = objective.kpiDisplay {
                HStack {
                    Image(systemName: objective.isReductionGoal ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(objective.isReductionGoal ? .orange : .green)
                    Text(kpiDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if objective.hasKpi {
                        Button {
                            onMeasure()
                        } label: {
                            Text("Medir")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.ctrlPurple.opacity(0.15))
                                .foregroundStyle(Color.ctrlPurple)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func progressColor(_ pct: Int) -> Color {
        if pct >= 70 { return .green }
        if pct >= 30 { return .yellow }
        return .red
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completado": return .green
        case "pausado":    return .orange
        case "cancelado":  return .red
        default:           return .blue
        }
    }
}

#Preview {
    ObjectivesView()
}
