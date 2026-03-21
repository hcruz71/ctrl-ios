import SwiftUI

struct UsageView: View {
    @State private var summary: UsageSummary?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let s = summary {
                ScrollView {
                    VStack(spacing: 20) {
                        // Circular gauge
                        gaugeSection(s)

                        // Details
                        detailsSection(s)

                        // Plan info
                        planSection(s)
                    }
                    .padding()
                }
            } else {
                Text("No se pudo cargar el uso")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Uso de IA")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadSummary() }
    }

    // MARK: - Gauge

    @ViewBuilder
    private func gaugeSection(_ s: UsageSummary) -> some View {
        let pct = Double(s.percentageUsed) / 100.0
        let color = gaugeColor(s.percentageUsed)

        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: pct)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: pct)

                VStack(spacing: 4) {
                    Text("\(s.interactionsUsed)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("de \(s.interactionsLimit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 160, height: 160)

            Text("\(s.percentageUsed)% usado")
                .font(.headline)
                .foregroundStyle(color)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Details

    @ViewBuilder
    private func detailsSection(_ s: UsageSummary) -> some View {
        VStack(spacing: 12) {
            detailRow("Interacciones restantes", value: "\(s.interactionsRemaining)")
            detailRow("Tokens entrada", value: formatNumber(s.tokensInputTotal))
            detailRow("Tokens salida", value: formatNumber(s.tokensOutputTotal))
            detailRow("Costo estimado", value: String(format: "$%.4f USD", s.costUsdTotal))
            detailRow("Fecha de reset", value: s.resetDate)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    // MARK: - Plan

    @ViewBuilder
    private func planSection(_ s: UsageSummary) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Plan actual")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(s.plan.capitalized)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.ctrlPurple.opacity(0.15))
                    .foregroundStyle(Color.ctrlPurple)
                    .clipShape(Capsule())
            }

            if s.plan == "free" {
                Text("Actualiza a Pro para obtener 300 interacciones/mes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func loadSummary() async {
        isLoading = true
        do {
            summary = try await APIClient.shared.request(.usageSummary)
        } catch {
            summary = nil
        }
        isLoading = false
    }

    private func gaugeColor(_ pct: Int) -> Color {
        if pct >= 90 { return .red }
        if pct >= 70 { return .orange }
        return .green
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
