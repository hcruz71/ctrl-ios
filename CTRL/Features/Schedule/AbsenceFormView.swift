import SwiftUI

struct AbsenceFormView: View {
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var type = "vacaciones"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var substituteName = ""
    @State private var substituteEmail = ""
    @State private var substitutePhone = ""
    @State private var notes = ""
    @State private var isSaving = false

    private let types = ["vacaciones", "licencia", "viaje", "otra"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tipo de ausencia") {
                    Picker("Tipo", selection: $type) {
                        ForEach(types, id: \.self) { t in
                            Text(t.capitalized).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Periodo") {
                    DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                    DatePicker("Fin", selection: $endDate, displayedComponents: .date)
                }

                Section("Sustituto") {
                    TextField("Nombre", text: $substituteName)
                    TextField("Email", text: $substituteEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefono", text: $substitutePhone)
                        .keyboardType(.phonePad)
                }

                Section("Notas") {
                    TextField("Instrucciones adicionales...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Guardar ausencia")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
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
            .navigationTitle("Nueva ausencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let body = CreateAbsenceBody(
            startDate: df.string(from: startDate),
            endDate: df.string(from: endDate),
            type: type,
            substituteName: substituteName.isEmpty ? nil : substituteName,
            substituteEmail: substituteEmail.isEmpty ? nil : substituteEmail,
            substitutePhone: substitutePhone.isEmpty ? nil : substitutePhone,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let _: UserAbsence = try await APIClient.shared.request(
                .absences, method: "POST", body: body
            )
            onSave()
            dismiss()
        } catch { }
        isSaving = false
    }
}
