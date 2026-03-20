import SwiftUI

struct MinutasView: View {
    @ObservedObject var vm: MeetingsViewModel
    let meetingId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var minuteText = ""
    @State private var resultMessage: String?
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isProcessingMinutes {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Claude está analizando la minuta…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !vm.suggestedTasks.isEmpty {
                    suggestedTasksList
                } else {
                    inputView
                }
            }
            .navigationTitle("Procesar minuta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .alert("Resultado", isPresented: .constant(resultMessage != nil)) {
                Button("OK") {
                    resultMessage = nil
                    dismiss()
                }
            } message: {
                Text(resultMessage ?? "")
            }
        }
    }

    // MARK: - Input view

    private var inputView: some View {
        VStack(spacing: 20) {
            Text("Ingresa el contenido de la minuta")
                .font(.headline)
                .padding(.top)

            HStack(spacing: 16) {
                Button {
                    showingImagePicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Foto")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingDocumentPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.fill")
                            .font(.title2)
                        Text("Documento")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)

            TextEditor(text: $minuteText)
                .frame(minHeight: 150)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal)

            if minuteText.isEmpty {
                Text("Pega o escribe el texto de la minuta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await vm.processMinutes(text: minuteText, meetingId: meetingId)
                }
            } label: {
                Text("Analizar con Claude")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(minuteText.isEmpty ? Color.gray : Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(minuteText.isEmpty)
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Suggested tasks list

    private var suggestedTasksList: some View {
        List {
            Section {
                ForEach($vm.suggestedTasks) { $task in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $task.included)
                            .labelsHidden()

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                BadgeView(
                                    text: typeLabel(task.type),
                                    color: typeColor(task.type)
                                )
                                if let level = task.priorityLevel {
                                    BadgeView(text: level, color: levelColor(level))
                                }
                            }
                            if let ctx = task.context, !ctx.isEmpty {
                                Text(ctx)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                            }
                            if let assignee = task.suggestedAssignee, !assignee.isEmpty {
                                Label(assignee, systemImage: "person")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("\(vm.suggestedTasks.filter(\.included).count) de \(vm.suggestedTasks.count) seleccionadas")
            }

            Section {
                Button {
                    Task {
                        if let result = await vm.confirmTasks(meetingId: meetingId) {
                            resultMessage = "Creadas \(result.tasksCreated) tareas y \(result.delegationsCreated) delegaciones"
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Registrar seleccionadas")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(vm.suggestedTasks.filter(\.included).isEmpty)
            }
        }
    }

    // MARK: - Helpers

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "delegate": return "Delegar"
        case "follow_up": return "Seguimiento"
        case "do_myself": return "Hacer yo"
        default: return type
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "delegate": return .red
        case "follow_up": return .orange
        case "do_myself": return .green
        default: return .gray
        }
    }

    private func levelColor(_ level: String) -> Color {
        switch level {
        case "A": return .red
        case "B": return .orange
        case "C": return .blue
        default: return .gray
        }
    }
}
