import SwiftUI

struct DelegationRowView: View {
    let delegation: Delegation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(delegation.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                BadgeView(text: delegation.status, color: statusColor)
            }

            Label(delegation.assignee, systemImage: "person")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if let dueDate = delegation.dueDate, !dueDate.isEmpty {
                    Label(dueDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let notes = delegation.notes, !notes.isEmpty {
                    Label(notes, systemImage: "note.text")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch delegation.status {
        case "pendiente":   return .orange
        case "en-progreso": return .ctrlBlue
        case "revision":    return .ctrlPurple
        case "completada":  return .green
        default:            return .gray
        }
    }
}
