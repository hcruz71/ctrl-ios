import SwiftUI

struct TaskRowView: View {
    let task: CTRLTask
    let onToggle: () -> Void
    var onChangePriority: ((String) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isDelegated == true
                      ? (task.done ? "person.fill.checkmark" : "person.fill")
                      : (task.done ? "checkmark.circle.fill" : "circle"))
                    .font(.title3)
                    .foregroundStyle(task.isDelegated == true
                                    ? .blue
                                    : (task.done ? Color.ctrlCoral : .secondary))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.done)
                    .foregroundStyle(task.done ? .secondary : .primary)

                HStack(spacing: 6) {
                    if let label = task.priorityLabel {
                        if let onChangePriority {
                            Menu {
                                if task.priorityLevel != "A" {
                                    Button {
                                        onChangePriority("A")
                                    } label: {
                                        Label("Urgente (A)", systemImage: "flame.fill")
                                    }
                                }
                                if task.priorityLevel != "B" {
                                    Button {
                                        onChangePriority("B")
                                    } label: {
                                        Label("Importante (B)", systemImage: "star.fill")
                                    }
                                }
                                if task.priorityLevel != "C" {
                                    Button {
                                        onChangePriority("C")
                                    } label: {
                                        Label("Pendiente (C)", systemImage: "clock.fill")
                                    }
                                }
                            } label: {
                                BadgeView(text: label, color: levelColor)
                            }
                        } else {
                            BadgeView(text: label, color: levelColor)
                        }
                    }
                    if let project = task.project, !project.isEmpty {
                        BadgeView(text: project, color: .ctrlPurple)
                    }
                }

                if task.isDelegated == true, let assignee = task.assignee {
                    Label(assignee, systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
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
