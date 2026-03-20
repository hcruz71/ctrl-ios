import SwiftUI

struct NetworkInsightView: View {
    let contacts: [Contact]
    @Environment(\.dismiss) private var dismiss

    private var operativos: Int { contacts.filter { $0.networkType == "operativa" }.count }
    private var personales: Int { contacts.filter { $0.networkType == "personal" }.count }
    private var estrategicos: Int { contacts.filter { $0.networkType == "estrategica" }.count }
    private var sinClasificar: Int {
        contacts.filter { $0.networkType == nil || $0.networkType?.isEmpty == true }.count
    }
    private var total: Int { contacts.count }

    private var operativoPct: Double { total > 0 ? Double(operativos) / Double(total) * 100 : 0 }
    private var estrategicoPct: Double { total > 0 ? Double(estrategicos) / Double(total) * 100 : 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    distributionChart
                    ibarraInsight
                    unclassifiedSection
                }
                .padding()
            }
            .navigationTitle("Analisis de red")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Distribution

    private var distributionChart: some View {
        VStack(spacing: 16) {
            Text("DISTRIBUCION DE CONTACTOS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Simple bar chart
            VStack(spacing: 12) {
                networkBar(label: "Operativa", count: operativos, color: .blue, icon: "wrench.and.screwdriver")
                networkBar(label: "Personal", count: personales, color: .green, icon: "leaf")
                networkBar(label: "Estrategica", count: estrategicos, color: .purple, icon: "target")
                networkBar(label: "Sin clasificar", count: sinClasificar, color: .gray, icon: "questionmark.circle")
            }

            Text("\(total) contactos en total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func networkBar(label: String, count: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.3))
                    .frame(
                        width: total > 0
                            ? geo.size.width * CGFloat(count) / CGFloat(max(total, 1))
                            : 0,
                        height: 8
                    )
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.subheadline.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: - Ibarra & Hunter Insight

    private var ibarraInsight: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INSIGHT — IBARRA & HUNTER")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if total == 0 {
                Text("Agrega contactos para ver el analisis de tu red profesional.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if operativoPct > 70 {
                insightCard(
                    icon: "exclamationmark.triangle",
                    color: .orange,
                    title: "Red concentrada en lo operativo",
                    message: "Tu red esta muy enfocada en el dia a dia (\(Int(operativoPct))% operativa). Los lideres efectivos invierten tiempo activo en contactos estrategicos y de desarrollo personal. Considera diversificar."
                )
            } else if estrategicoPct < 10 && total >= 5 {
                insightCard(
                    icon: "arrow.up.right",
                    color: .purple,
                    title: "Oportunidad estrategica",
                    message: "Solo \(Int(estrategicoPct))% de tu red es estrategica. Identifica lideres senior, stakeholders clave y contactos de alto impacto que puedan abrir oportunidades futuras."
                )
            } else {
                insightCard(
                    icon: "checkmark.seal",
                    color: .green,
                    title: "Red equilibrada",
                    message: "Tu red tiene buena diversidad entre contactos operativos, personales y estrategicos. Sigue cultivando relaciones en las tres categorias."
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func insightCard(icon: String, color: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Unclassified

    private var unclassifiedSection: some View {
        Group {
            if sinClasificar > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CONTACTOS SIN CLASIFICAR")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text("\(sinClasificar) contactos sin tipo de red asignado")
                        .font(.subheadline)

                    ForEach(contacts.filter({ $0.networkType == nil || $0.networkType?.isEmpty == true }).prefix(5)) { contact in
                        HStack {
                            Text(contact.name)
                                .font(.subheadline)
                            Spacer()
                            if let company = contact.company, !company.isEmpty {
                                Text(company)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if sinClasificar > 5 {
                        Text("y \(sinClasificar - 5) mas...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
