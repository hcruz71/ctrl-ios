import Foundation
import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var currentPlan: SubscriptionPlan = .free
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let productIds = [
        "com.hector.ctrl.pro.monthly",
        "com.hector.ctrl.team.monthly",
    ]

    private var transactionListener: Task<Void, Never>?

    var isPro: Bool { currentPlan == .pro || currentPlan == .team }
    var isTeam: Bool { currentPlan == .team }

    var proProduct: Product? { products.first { $0.id == productIds[0] } }
    var teamProduct: Product? { products.first { $0.id == productIds[1] } }

    private init() {}

    // MARK: - Load Products

    func loadProducts() async {
        do {
            products = try await Product.products(for: Set(productIds))
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "No se pudieron cargar los productos"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await verifyWithBackend(transaction: transaction)
            await transaction.finish()

        case .pending:
            errorMessage = "Compra pendiente de aprobacion"
        case .userCancelled:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Verify with Backend

    func verifyWithBackend(transaction: StoreKit.Transaction) async {
        do {
            struct VerifyBody: Encodable {
                let transactionId: String
            }
            struct VerifyResult: Codable {
                let plan: String
                let expiresAt: String?
                let isTrial: Bool?
            }
            let body = VerifyBody(transactionId: String(transaction.id))
            let result: VerifyResult = try await APIClient.shared.request(
                .subscriptionVerify, body: body
            )
            currentPlan = SubscriptionPlan(rawValue: result.plan) ?? .free
        } catch {
            errorMessage = "Error verificando con el servidor"
        }
    }

    // MARK: - Listen for Transaction Updates

    func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await verifyWithBackend(transaction: transaction)
                await transaction.finish()
            } catch {
                // Invalid transaction
            }
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await verifyWithBackend(transaction: transaction)
            } catch {
                continue
            }
        }
    }

    // MARK: - Check Current Entitlements

    func checkCurrentEntitlements() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                let plan = mapProductToPlan(transaction.productID)
                if plan != .free {
                    currentPlan = plan
                    return
                }
            }
        }
        // No active entitlements found
        currentPlan = .free
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func mapProductToPlan(_ productId: String) -> SubscriptionPlan {
        switch productId {
        case "com.hector.ctrl.pro.monthly": return .pro
        case "com.hector.ctrl.team.monthly": return .team
        default: return .free
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }
}
