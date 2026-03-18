import SwiftUI

/// Reusable contact picker — supports single selection (delegations) and multi selection (tasks).
struct ContactPickerView: View {
    @StateObject private var vm = ContactsViewModel()
    @Binding var selectedIds: Set<UUID>
    var singleSelection = false
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredContacts: [Contact] {
        if searchText.isEmpty { return vm.contacts }
        return vm.contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.company?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.contacts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.contacts.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle",
                        title: "Sin contactos",
                        message: "Crea contactos primero en la pestaña de Contactos."
                    )
                } else {
                    List {
                        ForEach(filteredContacts) { contact in
                            Button {
                                toggle(contact.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        if let company = contact.company, !company.isEmpty {
                                            Text(company)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()

                                    if selectedIds.contains(contact.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.ctrlPurple)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Buscar contacto")
                }
            }
            .navigationTitle(singleSelection ? "Seleccionar contacto" : "Seleccionar contactos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                if !singleSelection {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Listo") { dismiss() }
                    }
                }
            }
            .task { await vm.fetchContacts() }
        }
    }

    private func toggle(_ id: UUID) {
        if singleSelection {
            selectedIds = [id]
            dismiss()
        } else {
            if selectedIds.contains(id) {
                selectedIds.remove(id)
            } else {
                selectedIds.insert(id)
            }
        }
    }
}
