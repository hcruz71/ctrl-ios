import SwiftUI

struct ProjectPickerView: View {
    @StateObject private var vm = ProjectsViewModel()
    @Binding var selectedProjectId: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.projects.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.projects.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Sin proyectos")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Option to remove project association
                        Button {
                            selectedProjectId = nil
                            dismiss()
                        } label: {
                            HStack {
                                Text("Sin proyecto")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedProjectId == nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }

                        ForEach(vm.projects) { project in
                            Button {
                                selectedProjectId = project.id
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: project.icon)
                                        .foregroundStyle(Color(hex: project.color))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(project.name)
                                            .foregroundStyle(.primary)
                                        if let desc = project.description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if selectedProjectId == project.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.ctrlPurple)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Seleccionar proyecto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task { await vm.fetchProjects() }
        }
    }
}
