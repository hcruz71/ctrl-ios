import SwiftUI

struct ContactsView: View {
    @StateObject private var vm = ContactsViewModel()
    @State private var showingAdd = false
    @State private var showingNetworkInsight = false
    @State private var searchText = ""
    @State private var selectedTab = 0

    @State private var newName = ""
    @State private var newEmail = ""
    @State private var newPhone = ""
    @State private var newCompany = ""
    @State private var newRole = ""
    @State private var newNetworkType = ""
    @State private var newInfluenceLevel = ""
    @State private var newRelationshipStrength = 3

    private let tabs = ["Todos", "Operativa", "Personal", "Estrategica", "Sin clasificar"]
    private let networkTypes = [
        ("operativa", "Operativa", "wrench.and.screwdriver", "Trabajamos juntos en el dia a dia"),
        ("personal", "Personal", "leaf", "Apoya mi desarrollo profesional"),
        ("estrategica", "Estrategica", "target", "Conecta con oportunidades futuras"),
    ]

    private var filteredContacts: [Contact] {
        var list = vm.contacts

        // Tab filter
        switch selectedTab {
        case 1: list = list.filter { $0.networkType == "operativa" }
        case 2: list = list.filter { $0.networkType == "personal" }
        case 3: list = list.filter { $0.networkType == "estrategica" }
        case 4: list = list.filter { $0.networkType == nil || $0.networkType?.isEmpty == true }
        default: break
        }

        // Search filter
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                || ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
                || ($0.company?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tabs.indices, id: \.self) { i in
                            Button {
                                withAnimation { selectedTab = i }
                            } label: {
                                Text(tabs[i])
                                    .font(.caption)
                                    .fontWeight(selectedTab == i ? .semibold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTab == i ? Color.ctrlPurple : Color(.systemGray5))
                                    .foregroundStyle(selectedTab == i ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Content
                if vm.isLoading && vm.contacts.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredContacts.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Sin contactos")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredContacts) { contact in
                            ContactRowWithNetwork(contact: contact)
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
                    HStack(spacing: 12) {
                        Button {
                            showingNetworkInsight = true
                        } label: {
                            Image(systemName: "chart.pie")
                        }
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .withProfileButton()
            .sheet(isPresented: $showingAdd) { addContactSheet }
            .sheet(isPresented: $showingNetworkInsight) {
                NetworkInsightView(contacts: vm.contacts)
            }
            .task { await vm.fetchContacts() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Add Contact Sheet

    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section("Contacto") {
                    TextField("Nombre", text: $newName)
                    TextField("Email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefono", text: $newPhone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                Section("Organizacion") {
                    TextField("Empresa", text: $newCompany)
                    TextField("Rol / Puesto", text: $newRole)
                }
                Section("Tipo de red (Ibarra & Hunter)") {
                    ForEach(networkTypes, id: \.0) { nt in
                        Button {
                            withAnimation {
                                newNetworkType = newNetworkType == nt.0 ? "" : nt.0
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: nt.2)
                                    .frame(width: 24)
                                    .foregroundStyle(Color.ctrlPurple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(nt.1)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(nt.3)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if newNetworkType == nt.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }
                    }
                }
                Section("Nivel de influencia") {
                    Picker("Influencia", selection: $newInfluenceLevel) {
                        Text("Sin definir").tag("")
                        Text("Alto").tag("alto")
                        Text("Medio").tag("medio")
                        Text("Bajo").tag("bajo")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Fuerza de relacion") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= newRelationshipStrength ? "star.fill" : "star")
                                .foregroundStyle(star <= newRelationshipStrength ? .yellow : .gray)
                                .onTapGesture { newRelationshipStrength = star }
                        }
                    }
                    .font(.title3)
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
                            role: newRole.isEmpty ? nil : newRole,
                            networkType: newNetworkType.isEmpty ? nil : newNetworkType,
                            influenceLevel: newInfluenceLevel.isEmpty ? nil : newInfluenceLevel,
                            relationshipStrength: newRelationshipStrength
                        )
                        Task {
                            await vm.create(body)
                            showingAdd = false
                            newName = ""; newEmail = ""; newPhone = ""
                            newCompany = ""; newRole = ""; newNetworkType = ""
                            newInfluenceLevel = ""; newRelationshipStrength = 3
                        }
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Contact Row with Network Badge

private struct ContactRowWithNetwork: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(networkColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: contact.networkIcon)
                        .font(.subheadline)
                        .foregroundStyle(networkColor)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(contact.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let strength = contact.relationshipStrength, strength > 0 {
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { s in
                                Image(systemName: s <= strength ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(s <= strength ? .yellow : .clear)
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(contact.networkLabel)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(networkColor.opacity(0.1))
                        .foregroundStyle(networkColor)
                        .clipShape(Capsule())
                }
            }
            Spacer()
            if let level = contact.influenceLevel {
                Text(level.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var networkColor: Color {
        switch contact.networkType {
        case "operativa":   return .blue
        case "personal":    return .green
        case "estrategica": return .purple
        default:            return .gray
        }
    }
}

#Preview {
    ContactsView()
}
