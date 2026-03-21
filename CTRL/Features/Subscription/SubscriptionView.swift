import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var store = StoreManager.shared
    @State private var isPurchasing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current plan badge
                currentPlanHeader

                // Plan cards
                freePlanCard
                proPlanCard
                teamPlanCard

                // Restore + Legal
                footer
            }
            .padding()
        }
        .navigationTitle("Planes")
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.loadProducts() }
        .alert("Error", isPresented: .init(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: - Current Plan Header

    private var currentPlanHeader: some View {
        VStack(spacing: 8) {
            Text("Plan actual")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(store.currentPlan.label.uppercased())
                .font(.title2.bold())
                .foregroundStyle(planColor(store.currentPlan))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(planColor(store.currentPlan).opacity(0.15))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Plan Cards

    private var freePlanCard: some View {
        planCard(
            plan: .free,
            features: [
                "50 interacciones IA/mes",
                "Tareas y objetivos basicos",
                "Asistente de voz",
            ],
            price: "Gratis"
        )
    }

    private var proPlanCard: some View {
        let price = store.proProduct?.displayPrice ?? "$9.99"
        return planCard(
            plan: .pro,
            features: [
                "300 interacciones IA/mes",
                "Todas las funciones",
                "Google Calendar sync",
                "MCP server para Claude.ai",
            ],
            price: "\(price)/mes",
            product: store.proProduct
        )
    }

    private var teamPlanCard: some View {
        let price = store.teamProduct?.displayPrice ?? "$29.99"
        return planCard(
            plan: .team,
            features: [
                "1,000 interacciones IA/mes",
                "Todo lo de Pro",
                "5 usuarios incluidos",
                "Dashboard de equipo (proximamente)",
            ],
            price: "\(price)/mes",
            product: store.teamProduct
        )
    }

    @ViewBuilder
    private func planCard(
        plan: SubscriptionPlan,
        features: [String],
        price: String,
        product: Product? = nil
    ) -> some View {
        let isCurrent = store.currentPlan == plan

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.label.uppercased())
                    .font(.headline)
                    .foregroundStyle(planColor(plan))
                Spacer()
                Text(price)
                    .font(.subheadline.bold())
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(planColor(plan))
                }
            }

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(planColor(plan))
                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !isCurrent, let product {
                Button {
                    Task {
                        isPurchasing = true
                        try? await store.purchase(product)
                        isPurchasing = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Suscribirse")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(planColor(plan))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isPurchasing)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? planColor(plan) : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("Restaurar compras")
                    .font(.subheadline)
                    .foregroundStyle(Color.ctrlPurple)
            }

            Text("La suscripcion se renueva automaticamente a menos que se cancele al menos 24 horas antes del final del periodo actual. Puedes gestionar y cancelar tu suscripcion en Configuracion > [tu nombre] > Suscripciones.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func planColor(_ plan: SubscriptionPlan) -> Color {
        switch plan {
        case .free: return .gray
        case .pro:  return Color.ctrlPurple
        case .team: return .orange
        }
    }
}
