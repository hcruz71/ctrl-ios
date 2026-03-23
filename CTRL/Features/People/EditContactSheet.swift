import SwiftUI

struct EditContactSheet: View {
    @ObservedObject var vm: ContactsViewModel
    let contact: Contact
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var role = ""
    @State private var networkType = ""
    @State private var influenceLevel = ""
    @State private var relationshipStrength = 3
    @State private var networkNotes = ""
    @State private var isSaving = false
    @State private var didLoad = false

    private let networkTypes = [
        ("operativa", "Operativa", "wrench.and.screwdriver", "Trabajamos juntos en el dia a dia"),
        ("personal", "Personal", "leaf", "Apoya mi desarrollo profesional"),
        ("estrategica", "Estrategica", "target", "Conecta con oportunidades futuras"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Contacto") {
                    TextField("Nombre", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefono", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section("Organizacion") {
                    TextField("Empresa", text: $company)
                    TextField("Rol / Puesto", text: $role)
                }

                Section("Tipo de red") {
                    ForEach(networkTypes, id: \.0) { nt in
                        Button {
                            withAnimation { networkType = networkType == nt.0 ? "" : nt.0 }
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
                                if networkType == nt.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.ctrlPurple)
                                }
                            }
                        }
                    }
                }

                Section("Nivel de influencia") {
                    Picker("Influencia", selection: $influenceLevel) {
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
                            Image(systemName: star <= relationshipStrength ? "star.fill" : "star")
                                .foregroundStyle(star <= relationshipStrength ? .yellow : .gray)
                                .onTapGesture { relationshipStrength = star }
                        }
                    }
                    .font(.title3)
                }

                Section("Notas de red") {
                    TextField("Notas sobre la relacion...", text: $networkNotes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationTitle("Editar contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await save() }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
        .onAppear { loadContact() }
        .presentationDetents([.medium, .large])
    }

    private func loadContact() {
        guard !didLoad else { return }
        didLoad = true
        name = contact.name
        email = contact.email ?? ""
        phone = contact.phone ?? ""
        company = contact.company ?? ""
        role = contact.role ?? ""
        networkType = contact.networkType ?? ""
        influenceLevel = contact.influenceLevel ?? ""
        relationshipStrength = contact.relationshipStrength ?? 3
        networkNotes = contact.networkNotes ?? ""
    }

    private func save() async {
        isSaving = true
        let body = UpdateContactBody(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            company: company.isEmpty ? nil : company,
            role: role.isEmpty ? nil : role,
            networkType: networkType.isEmpty ? nil : networkType,
            networkNotes: networkNotes.isEmpty ? nil : networkNotes,
            influenceLevel: influenceLevel.isEmpty ? nil : influenceLevel,
            relationshipStrength: relationshipStrength
        )
        await vm.update(id: contact.id, body: body)
        dismiss()
        isSaving = false
    }
}
