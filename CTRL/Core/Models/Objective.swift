import Foundation

struct Objective: Codable, Identifiable {
    let id: UUID
    var title: String
    var keyResult: String?
    var area: String?
    var horizon: String?
    var progress: Int

    // SMART
    var smartSpecific: String?
    var smartMeasurable: String?
    var smartAchievable: String?
    var smartRelevant: String?
    var smartTimeBound: String?

    // KPI
    var kpiName: String?
    var kpiTarget: Double?
    var kpiCurrent: Double?
    var kpiUnit: String?
    var kpiBaseline: Double?
    var kpiFrequency: String?

    // Status
    var completionCriteria: String?
    var status: String?
    var completedAt: Date?

    let createdAt: Date?
    let updatedAt: Date?

    var hasKpi: Bool {
        kpiName != nil && kpiTarget != nil
    }

    var kpiProgress: Int {
        guard let target = kpiTarget, let baseline = kpiBaseline, let current = kpiCurrent else {
            return progress
        }
        let range = target - baseline
        guard range != 0 else { return 0 }
        let raw = ((current - baseline) / range) * 100
        return Int(max(0, min(100, raw)))
    }

    var isCompleted: Bool {
        status == "completado"
    }

    var kpiDisplay: String? {
        guard let name = kpiName, let target = kpiTarget, let unit = kpiUnit else {
            return nil
        }
        let current = kpiCurrent ?? kpiBaseline ?? 0
        return "\(name): \(formatNum(current)) / \(formatNum(target)) \(unit)"
    }

    var effectiveProgress: Int {
        hasKpi ? kpiProgress : progress
    }

    private func formatNum(_ n: Double) -> String {
        n == n.rounded() ? String(Int(n)) : String(format: "%.1f", n)
    }
}

enum ObjectiveArea: String, CaseIterable, Identifiable {
    case personal
    case laboral
    case espiritual
    case financiero
    case familiar
    case negocio

    var id: String { rawValue }

    var label: String {
        switch self {
        case .personal:    return "Personal"
        case .laboral:     return "Laboral"
        case .espiritual:  return "Espiritual"
        case .financiero:  return "Financiero"
        case .familiar:    return "Familiar"
        case .negocio:     return "Negocio"
        }
    }

    var icon: String {
        switch self {
        case .personal:    return "figure.mind.and.body"
        case .laboral:     return "briefcase.fill"
        case .espiritual:  return "hands.sparkles"
        case .financiero:  return "dollarsign.circle"
        case .familiar:    return "figure.2.and.child.holdinghands"
        case .negocio:     return "building.2"
        }
    }

    var emoji: String {
        switch self {
        case .personal:    return "🧘"
        case .laboral:     return "💼"
        case .espiritual:  return "🙏"
        case .financiero:  return "💰"
        case .familiar:    return "👨‍👩‍👧"
        case .negocio:     return "🏢"
        }
    }
}

enum ObjectiveStatus: String, CaseIterable, Identifiable {
    case activo
    case completado
    case pausado
    case cancelado

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

struct CreateObjectiveBody: Encodable {
    var title: String
    var keyResult: String?
    var area: String?
    var horizon: String?
    var progress: Int = 0
    var smartSpecific: String?
    var smartMeasurable: String?
    var smartAchievable: String?
    var smartRelevant: String?
    var smartTimeBound: String?
    var kpiName: String?
    var kpiTarget: Double?
    var kpiCurrent: Double?
    var kpiUnit: String?
    var kpiBaseline: Double?
    var kpiFrequency: String?
    var completionCriteria: String?
}

struct UpdateObjectiveBody: Encodable {
    var title: String?
    var keyResult: String?
    var area: String?
    var horizon: String?
    var progress: Int?
    var smartSpecific: String?
    var smartMeasurable: String?
    var smartAchievable: String?
    var smartRelevant: String?
    var smartTimeBound: String?
    var kpiName: String?
    var kpiTarget: Double?
    var kpiCurrent: Double?
    var kpiUnit: String?
    var kpiBaseline: Double?
    var kpiFrequency: String?
    var completionCriteria: String?
    var status: String?
}

struct KpiMeasurement: Codable, Identifiable {
    let id: UUID
    var value: Double
    var notes: String?
    let measuredAt: Date?
}

struct UpdateKpiBody: Encodable {
    var kpiCurrent: Double
    var notes: String?
}
