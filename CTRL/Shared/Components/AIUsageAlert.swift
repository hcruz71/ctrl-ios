import SwiftUI

/// Reusable confirmation alert for AI-powered actions.
/// Shows remaining interactions and asks for confirmation before calling Claude.
struct AIUsageAlert: ViewModifier {
    @Binding var isPresented: Bool
    var onConfirm: () -> Void
    var title: String = "Accion con IA"
    var detail: String = ""
    var estimatedUsage: String = "1-2"

    @State private var usageSummary: UsageSummary?
    @State private var loaded = false

    private var remaining: Int { usageSummary?.interactionsRemaining ?? 0 }

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button("Continuar") { onConfirm() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                let base = detail.isEmpty
                    ? "Esta accion usara aproximadamente \(estimatedUsage) interacciones de IA."
                    : detail
                let usage = "Te quedan \(remaining) interacciones este mes."
                let warning = remaining < 10 ? "\nAtencion: quedan pocas interacciones." : ""
                Text("\(base)\n\(usage)\(warning)")
            }
            .task {
                guard !loaded else { return }
                loaded = true
                do {
                    usageSummary = try? await APIClient.shared.request(.usageSummary)
                }
            }
    }
}

extension View {
    func aiUsageAlert(
        isPresented: Binding<Bool>,
        title: String = "Accion con IA",
        detail: String = "",
        estimatedUsage: String = "1-2",
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(AIUsageAlert(
            isPresented: isPresented,
            onConfirm: onConfirm,
            title: title,
            detail: detail,
            estimatedUsage: estimatedUsage
        ))
    }
}
