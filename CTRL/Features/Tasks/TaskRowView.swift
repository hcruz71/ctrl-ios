import SwiftUI

struct TaskRowView: View {
    let task: CTRLTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.done ? Color.ctrlCoral : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.done)
                    .foregroundStyle(task.done ? .secondary : .primary)

                HStack(spacing: 6) {
                    if let label = task.priorityLabel {
                        BadgeView(text: label, color: levelColor)
                    }
                    if let project = task.project, !project.isEmpty {
                        BadgeView(text: project, color: .ctrlPurple)
                    }
                }

                if let dueDate = task.dueDate, !dueDate.isEmpty {
                    Label(dueDate, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var levelColor: Color {
        switch task.priorityLevel {
        case "A": return .red
        case "B": return .orange
        case "C": return .blue
        default: return .gray
        }
    }
}
