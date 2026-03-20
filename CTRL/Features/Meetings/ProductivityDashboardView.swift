import SwiftUI

struct ProductivityDashboardView: View {
    @ObservedObject var vm: MeetingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let p = vm.productivity {
                    ScrollView {
                        VStack(spacing: 20) {
                            weekSummary(p)
                            objectiveBreakdown(p)
                            topContacts(p)
                            busiestDay(p)
                        }
                        .padding()
                    }
                } else {
                    Text("No hay datos disponibles")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Productividad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                await vm.fetchProductivity()
                isLoading = false
            }
        }
    }

    // MARK: - Weekly Summary

    private func weekSummary(_ p: MeetingProductivity) -> some View {
        VStack(spacing: 16) {
            Text("RESUMEN SEMANAL")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Coverage gauge
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: Double(p.objectiveCoveragePct) / 100)
                    .stroke(
                        coverageColor(p.objectiveCoveragePct),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(p.objectiveCoveragePct)%")
                        .font(.title2.bold())
                    Text("con objetivo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                metricBox(value: "\(p.totalThisWeek)", label: "Total", color: .primary)
                metricBox(value: "\(p.withObjective)", label: "Con objetivo", color: .green)
                metricBox(value: "\(p.withoutObjective)", label: "Sin objetivo", color: .orange)
                metricBox(
                    value: String(format: "%.1f", p.avgMeetingsPerDay),
                    label: "Promedio/dia",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func coverageColor(_ pct: Int) -> Color {
        if pct >= 70 { return .green }
        if pct >= 30 { return .yellow }
        return .red
    }

    private func metricBox(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - By Objective

    private func objectiveBreakdown(_ p: MeetingProductivity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REUNIONES POR OBJETIVO")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if p.byObjective.isEmpty {
                Text("Ninguna reunion vinculada a objetivos esta semana")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                let maxCount = p.byObjective.map(\.meetingCount).max() ?? 1
                ForEach(p.byObjective, id: \.objectiveTitle) { item in
                    HStack {
                        Text(item.objectiveTitle)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.meetingCount)")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.ctrlPurple)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ctrlPurple.opacity(0.3))
                            .frame(
                                width: geo.size.width * CGFloat(item.meetingCount) / CGFloat(maxCount),
                                height: 6
                            )
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Top Contacts

    private func topContacts(_ p: MeetingProductivity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTACTOS MAS FRECUENTES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if p.topContacts.isEmpty {
                Text("Sin datos de participantes esta semana")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(p.topContacts, id: \.name) { contact in
                    HStack {
                        Circle()
                            .fill(Color.ctrlPurple.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(contact.name.prefix(1)).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.ctrlPurple)
                            }
                        Text(contact.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(contact.meetingCount) reuniones")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Busiest Day

    private func busiestDay(_ p: MeetingProductivity) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("DIA MAS OCUPADO")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(p.busiestDay)
                    .font(.title3.bold())
            }
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)
                .foregroundStyle(Color.ctrlPurple)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
