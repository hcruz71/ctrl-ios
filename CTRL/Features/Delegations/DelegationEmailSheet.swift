import SwiftUI

struct DelegationEmailSheet: View {
    @ObservedObject var vm: DelegationsViewModel
    let delegation: Delegation
    @Environment(\.dismiss) private var dismiss

    // Step tracking
    enum Step { case context, generating, preview, sent }
    @State private var step: Step = .context

    // Context form fields
    @State private var objetivoVinculado = ""
    @State private var contextoAdicional = ""
    @State private var recursosDisponibles = ""
    @State private var checkpointDias = ""
    @State private var nivelAutonomia = "supervisado"
    @State private var tono = "formal"

    // Generated email
    @State private var emailSubject = ""
    @State private var emailDraft = ""

    private let nivelesAutonomia = [
        ("total", "Total", "Plena autonomia en decisiones"),
        ("supervisado", "Supervisado", "Actualizacion semanal de avance"),
        ("con_aprobacion", "Con aprobacion", "Consulta antes de decidir"),
    ]

    private let tonos = [
        ("formal", "Formal"),
        ("colaborativo", "Colaborativo"),
        ("urgente", "Urgente"),
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .context:
                    contextForm
                case .generating:
                    ProgressView("Generando correo con IA...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .preview:
                    previewView
                case .sent:
                    sentConfirmation
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private var navigationTitle: String {
        switch step {
        case .context:    return "Contexto del correo"
        case .generating: return "Generando..."
        case .preview:    return "Vista previa"
        case .sent:       return "Enviado"
        }
    }

    // MARK: - Step 1: Context Form

    private var contextForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(delegation.title)
                        .font(.headline)
                    Text("Para: \(delegation.assignee)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let due = delegation.dueDate {
                        Text("Fecha limite: \(due)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Delegacion")
            }

            Section {
                TextField(
                    "Ej: Incrementar ventas Q2, Lanzamiento producto...",
                    text: $objetivoVinculado,
                    axis: .vertical
                )
                .lineLimit(2...4)
            } header: {
                Text("Objetivo estrategico vinculado")
            } footer: {
                Text("A cual de tus objetivos contribuye esta tarea")
            }

            Section {
                TextField(
                    "Antecedentes que el responsable debe conocer...",
                    text: $contextoAdicional,
                    axis: .vertical
                )
                .lineLimit(3...6)
            } header: {
                Text("Contexto y antecedentes")
            }

            Section {
                TextField(
                    "Herramientas, presupuesto, equipo disponible...",
                    text: $recursosDisponibles,
                    axis: .vertical
                )
                .lineLimit(2...4)
            } header: {
                Text("Recursos disponibles")
            }

            Section {
                TextField("Ej: 3, 5, 7", text: $checkpointDias)
                    .keyboardType(.numberPad)
            } header: {
                Text("Primer checkpoint (dias)")
            } footer: {
                Text("En cuantos dias se revisara el avance")
            }

            Section("Nivel de autonomia") {
                ForEach(nivelesAutonomia, id: \.0) { nivel in
                    Button {
                        withAnimation { nivelAutonomia = nivel.0 }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(nivel.1)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(nivel.2)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if nivelAutonomia == nivel.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.ctrlPurple)
                            }
                        }
                    }
                }
            }

            Section("Tono del correo") {
                Picker("Tono", selection: $tono) {
                    ForEach(tonos, id: \.0) { t in
                        Text(t.1).tag(t.0)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button {
                    Task { await generateEmail() }
                } label: {
                    HStack {
                        Spacer()
                        Label("Generar correo con IA", systemImage: "sparkles")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .listRowBackground(Color.ctrlPurple)
                .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Step 2: Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            // Subject
            VStack(alignment: .leading, spacing: 4) {
                Text("Asunto:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(emailSubject)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))

            Divider()

            // Editable body
            TextEditor(text: $emailDraft)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    step = .context
                } label: {
                    Text("Editar contexto")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task { await generateEmail() }
                } label: {
                    Label("Regenerar", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Task { await sendEmail() }
                } label: {
                    Label("Enviar", systemImage: "paperplane.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.ctrlPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
    }

    // MARK: - Step 3: Sent

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Correo marcado como enviado")
                .font(.headline)
            Text(delegation.assignee)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let email = delegation.contact?.email, !email.isEmpty {
                Button {
                    UIPasteboard.general.string = emailDraft
                } label: {
                    Label("Copiar correo al portapapeles", systemImage: "doc.on.doc")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    Text("El contacto no tiene email registrado")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        UIPasteboard.general.string = emailDraft
                    } label: {
                        Label("Copiar al portapapeles", systemImage: "doc.on.doc")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func generateEmail() async {
        step = .generating

        let checkpointStr: String? = {
            guard let dias = Int(checkpointDias), dias > 0 else { return nil }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let date = Calendar.current.date(byAdding: .day, value: dias, to: Date())!
            return df.string(from: date)
        }()

        let context = DelegationEmailContext(
            objetivoVinculado: objetivoVinculado.isEmpty ? nil : objetivoVinculado,
            contextoAdicional: contextoAdicional.isEmpty ? nil : contextoAdicional,
            recursosDisponibles: recursosDisponibles.isEmpty ? nil : recursosDisponibles,
            fechaPrimerCheckpoint: checkpointStr,
            nivelAutonomia: nivelAutonomia,
            tono: tono
        )

        if let result = await vm.prepareSmartEmail(
            id: delegation.id,
            context: context,
            send: false
        ) {
            emailSubject = result.emailSubject
            emailDraft = result.emailDraft
            step = .preview
        } else {
            step = .context
        }
    }

    private func sendEmail() async {
        let context = DelegationEmailContext(
            nivelAutonomia: nivelAutonomia,
            tono: tono
        )

        if let result = await vm.prepareSmartEmail(
            id: delegation.id,
            context: context,
            send: true
        ) {
            emailDraft = result.emailDraft
            step = .sent
        }
    }
}
