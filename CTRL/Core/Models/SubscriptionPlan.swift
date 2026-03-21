import Foundation

enum SubscriptionPlan: String, Codable {
    case free
    case pro
    case team

    var label: String {
        switch self {
        case .free: return "Free"
        case .pro:  return "Pro"
        case .team: return "Team"
        }
    }

    var interactionsLimit: Int {
        switch self {
        case .free: return 50
        case .pro:  return 300
        case .team: return 1000
        }
    }

    var productId: String? {
        switch self {
        case .free: return nil
        case .pro:  return "com.hector.ctrl.pro.monthly"
        case .team: return "com.hector.ctrl.team.monthly"
        }
    }
}

struct SubscriptionStatus: Codable {
    let plan: String
    let expiresAt: String?
    let productId: String?
    let subscription: SubscriptionDetail?
}

struct SubscriptionDetail: Codable {
    let status: String
    let isTrial: Bool?
    let purchaseDate: String?
    let expiresDate: String?
}
