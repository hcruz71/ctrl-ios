import SwiftUI

struct ContactsView: View {
    @StateObject private var vm = ContactsViewModel()
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var newPhone = ""
    @State private var newCompany = ""
    @State private var newRole = ""

    private var filteredContacts: [Contact] {
        if searchText.isEmpty { return vm.contacts }
        return vm.contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
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
                        message: "Agrega contactos para asignarlos a tareas y delegaciones."
                    )
                } else {
                    List {
                        ForEach(filteredContacts) { contact in
                            ContactRowView(contact: contact)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(id: contact.id) }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.fetchContacts() }
                    .searchable(text: $searchText, prompt: "Buscar contacto")
                }
            }
            .navigationTitle("Contactos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) {
                addContactSheet
            }
            .task { await vm.fetchContacts() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section("Contacto") {
                    TextField("Nombre", text: $newName)
                    TextField("Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Teléfono", text: $newPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                Section("Organización") {
                    TextField("Empresa", text: $newCompany)
                    TextField("Rol / Puesto", text: $newRole)
                }
            }
            .navigationTitle("Nuevo contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let body = CreateContactBody(
                            name: newName,
                            email: newEmail.isEmpty ? nil : newEmail,
                            phone: newPhone.isEmpty ? nil : newPhone,
                            company: newCompany.isEmpty ? nil : newCompany,
                            role: newRole.isEmpty ? nil : newRole
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newName = ""
                            newEmail = ""
                            newPhone = ""
                            newCompany = ""
                            newRole = ""
                        }
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ContactsView()
}
