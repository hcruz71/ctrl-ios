import SwiftUI

struct DelegationsView: View {
    @StateObject private var vm = DelegationsViewModel()
    @State private var showingAdd = false
    @State private var newTitle = ""
    @State private var newAssignee = ""
    @State private var newNotes = ""
    @State private var newDueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedContactIds: Set<UUID> = []
    @State private var showingContactPicker = false

    private let statuses = ["pendiente", "en-progreso", "revision", "completada"]

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.delegations.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.delegations.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: "Sin delegaciones",
                        message: "Delega tareas a tu equipo."
                    )
                } else {
                    List {
                        ForEach(vm.delegations) { delegation in
                            DelegationRowView(delegation: delegation)
                                .contextMenu {
                                    ForEach(statuses, id: \.self) { status in
                                        Button(status.capitalized) {
                                            Task {
                                                await vm.updateStatus(
                                                    id: delegation.id,
                                                    status: status
                                                )
                                            }
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(id: delegation.id) }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchDelegations() }
                }
            }
            .navigationTitle("Delegaciones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                addDelegationSheet
            }
            .task { await vm.fetchDelegations() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addDelegationSheet: some View {
        NavigationStack {
            Form {
                Section("Delegación") {
                    TextField("Título", text: $newTitle)
                    TextField("Asignado a", text: $newAssignee)
                }
                Section("Contacto") {
                    Button {
                        showingContactPicker = true
                    } label: {
                        HStack {
                            Text("Responsable")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedContactIds.isEmpty ? "Ninguno" : "1 seleccionado")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Detalles") {
                    TextField("Notas o instrucciones", text: $newNotes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle("Fecha límite", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Fecha", selection: $newDueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Nueva delegación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"

                        let body = CreateDelegationBody(
                            title: newTitle,
                            assignee: newAssignee,
                            dueDate: hasDueDate ? df.string(from: newDueDate) : nil,
                            notes: newNotes.isEmpty ? nil : newNotes,
                            contactId: selectedContactIds.first?.uuidString
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newTitle = ""
                            newAssignee = ""
                            newNotes = ""
                            hasDueDate = false
                            selectedContactIds = []
                        }
                    }
                    .disabled(newTitle.isEmpty || newAssignee.isEmpty)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedIds: $selectedContactIds, singleSelection: true)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    DelegationsView()
}
