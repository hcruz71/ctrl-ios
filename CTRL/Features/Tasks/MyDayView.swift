import SwiftUI

struct MyDayView: View {
    @ObservedObject var vm: TasksViewModel

    private var tasksA: [CTRLTask] { vm.tasksA }
    private var completed: Int { tasksA.filter(\.done).count }
    private var total: Int { tasksA.count }

    var body: some View {
        VStack(spacing: 16) {
            // Progress header
            VStack(spacing: 8) {
                Text("Mi Día")
                    .font(.title2)
                    .fontWeight(.bold)

                if total > 0 {
                    ProgressView(value: Double(completed), total: Double(total))
                        .tint(.red)
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 40)

                    Text("\(completed) de \(total) tareas urgentes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No hay tareas urgentes (A)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)

            if tasksA.isEmpty {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("¡Todo al día!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(tasksA) { task in
                        HStack(spacing: 16) {
                            Button {
                                Task { await vm.toggleDone(task: task) }
                            } label: {
                                Image(
                                    systemName: task.done
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .font(.title)
                                .foregroundStyle(task.done ? .green : .red)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.priorityLabel ?? "A")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)

                                Text(task.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .strikethrough(task.done)
                                    .foregroundStyle(task.done ? .secondary : .primary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
