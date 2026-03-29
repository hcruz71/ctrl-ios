import SwiftUI
import WatchKit

struct WatchTasksView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if connectivity.tasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Sin tareas urgentes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(connectivity.tasks) { task in
                        Button {
                            completeTask(task)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(task.done ? .green : .secondary)
                                    .font(.body)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .strikethrough(task.done)
                                    if let label = task.priorityLabel {
                                        Text(label)
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Tareas A")
        .task {
            await loadTasks()
        }
    }

    private func loadTasks() async {
        // Try direct API first (Watch independent)
        if WatchAPIService.shared.isAuthenticated {
            do {
                let tasks: [WatchTask] = try await WatchAPIService.shared.request("/tasks/today")
                let filtered = tasks.filter { $0.priorityLevel == "A" && !$0.done }
                connectivity.tasks = Array(filtered.prefix(10))
                return
            } catch {}
        }
        // Fallback: request via iPhone
        connectivity.requestTasks()
    }

    private func completeTask(_ task: WatchTask) {
        WKInterfaceDevice.current().play(.success)
        connectivity.completeTask(id: task.id)
    }
}
