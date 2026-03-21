import SwiftUI

struct ProjectDetailView: View {
    @ObservedObject var vm: ProjectsViewModel
    let project: Project
    @State private var selectedTab = 0
    @State private var summary: ProjectSummary?
    @State private var isLoadingSummary = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            projectHeader

            // Tab picker
            Picker("Seccion", selection: $selectedTab) {
                Text("Tareas").tag(0)
                Text("Reuniones").tag(1)
                Text("Delegaciones").tag(2)
                Text("Resumen").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab content
            Group {
                switch selectedTab {
                case 0: tasksTab
                case 1: meetingsTab
                case 2: delegationsTab
                case 3: summaryTab
                default: EmptyView()
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSummary()
        }
    }

    // MARK: - Header

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: project.icon)
                    .font(.title2)
                    .foregroundStyle(Color.ctrlPurple)
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.title3.bold())
                    if let desc = project.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(project.priorityLevel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundStyle(priorityColor)
                    .clipShape(Capsule())
            }

            // Dates
            if project.startDate != nil || project.endDate != nil {
                HStack(spacing: 12) {
                    if let start = project.startDate {
                        Label(start, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if project.startDate != nil && project.endDate != nil {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if let end = project.endDate {
                        Label(end, systemImage: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ctrlPurple)
                            .frame(width: geo.size.width * CGFloat(project.taskProgress) / 100)
                    }
                }
                .frame(height: 8)

                Text("\(project.taskProgress)%")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.ctrlPurple)
                    .frame(width: 40, alignment: .trailing)
            }

            // Linked objective
            if let obj = project.objective {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption)
                    Text(obj.title)
                        .font(.caption)
                }
                .foregroundStyle(Color.ctrlPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.ctrlPurple.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Tabs

    private var tasksTab: some View {
        Group {
            if let s = summary {
                VStack(spacing: 0) {
                    // Stats row
                    HStack(spacing: 16) {
                        statBadge("Pendientes", "\(s.tasks.total - s.tasks.completed)", .orange)
                        statBadge("Completadas", "\(s.tasks.completed)", .green)
                        statBadge("Total", "\(s.tasks.total)", .blue)
                    }
                    .padding()

                    if s.tasks.total == 0 {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("Sin tareas en este proyecto")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        // Priority breakdown
                        List {
                            if let byPriority = s.tasks.byPriority {
                                ForEach(["A", "B", "C"], id: \.self) { level in
                                    if let count = byPriority[level], count > 0 {
                                        HStack {
                                            priorityIcon(level)
                                            Text("Prioridad \(level)")
                                                .font(.subheadline)
                                            Spacer()
                                            Text("\(count)")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var meetingsTab: some View {
        Group {
            if let s = summary {
                if s.meetings.total == 0 {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Sin reuniones en este proyecto")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        HStack(spacing: 16) {
                            statBadge("Total", "\(s.meetings.total)", .blue)
                        }
                        .padding()
                        Spacer()
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var delegationsTab: some View {
        Group {
            if let s = summary {
                if s.delegations.total == 0 {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Sin delegaciones en este proyecto")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        HStack(spacing: 16) {
                            statBadge("Activas", "\(s.delegations.active)", .orange)
                            statBadge("Total", "\(s.delegations.total)", .blue)
                        }
                        .padding()
                        Spacer()
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var summaryTab: some View {
        Group {
            if isLoadingSummary {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let s = summary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Progress
                        summaryCard("Avance", systemImage: "chart.bar.fill") {
                            Text("\(s.tasks.progress)% completado")
                                .font(.title2.bold())
                            Text("\(s.tasks.completed) de \(s.tasks.total) tareas")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Delegations
                        summaryCard("Delegaciones", systemImage: "person.2.fill") {
                            HStack(spacing: 16) {
                                VStack {
                                    Text("\(s.delegations.active)")
                                        .font(.title3.bold())
                                    Text("Activas")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                VStack {
                                    Text("\(s.delegations.total - s.delegations.active)")
                                        .font(.title3.bold())
                                    Text("Completadas")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Meetings
                        summaryCard("Reuniones", systemImage: "calendar") {
                            Text("\(s.meetings.total) reuniones vinculadas")
                                .font(.subheadline)
                        }

                        // Objective
                        if let obj = project.objective {
                            summaryCard("Objetivo vinculado", systemImage: "target") {
                                Text(obj.title)
                                    .font(.subheadline.bold())
                                Text("\(obj.effectiveProgress)% de avance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("No se pudo cargar el resumen")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private func loadSummary() async {
        isLoadingSummary = true
        summary = await vm.getSummary(id: project.id)
        isLoadingSummary = false
    }

    private func statBadge(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func summaryCard<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func priorityIcon(_ level: String) -> some View {
        switch level {
        case "A":
            Image(systemName: "flame.fill")
                .foregroundStyle(.red)
        case "B":
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
        default:
            Image(systemName: "clock.fill")
                .foregroundStyle(.blue)
        }
    }

    private var priorityColor: Color {
        switch project.priorityLevel {
        case "A": return .red
        case "B": return .orange
        default: return .blue
        }
    }
}
