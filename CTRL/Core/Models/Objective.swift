import Foundation
import SwiftUI

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

    var isReductionGoal: Bool {
        guard let target = kpiTarget, let baseline = kpiBaseline else { return false }
        return target < baseline
    }

    var kpiProgress: Int {
        guard let target = kpiTarget, let baseline = kpiBaseline, let current = kpiCurrent else {
            return progress
        }
        guard baseline != target else { return 0 }
        let raw: Double
        if isReductionGoal {
            raw = ((baseline - current) / (baseline - target)) * 100
        } else {
            raw = ((current - baseline) / (target - baseline)) * 100
        }
        return Int(max(0, min(100, raw)))
    }

    var isCompleted: Bool {
        guard let current = kpiCurrent,
              let target = kpiTarget,
              let baseline = kpiBaseline else {
            return status == "completado"
        }
        return target < baseline ? current <= target : current >= target
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
    case salud = "salud"
    case profesional = "profesional"
    case financiero = "financiero"
    case familia = "familia"
    case crecimiento = "crecimiento"
    case espiritual = "espiritual"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .salud:        return "Salud & Bienestar"
        case .profesional:  return "Profesional & Negocios"
        case .financiero:   return "Financiero"
        case .familia:      return "Familia & Relaciones"
        case .crecimiento:  return "Crecimiento Personal"
        case .espiritual:   return "Espiritual & Recreación"
        }
    }

    var emoji: String {
        switch self {
        case .salud:        return "💪"
        case .profesional:  return "💼"
        case .financiero:   return "💰"
        case .familia:      return "👨‍👩‍👧"
        case .crecimiento:  return "🌱"
        case .espiritual:   return "✨"
        }
    }

    var color: Color {
        switch self {
        case .salud:        return .green
        case .profesional:  return .blue
        case .financiero:   return Color(hex: "#FFD700")
        case .familia:      return .orange
        case .crecimiento:  return .purple
        case .espiritual:   return .cyan
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
