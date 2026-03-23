import SwiftUI

struct TaskEmailSheet: View {
    let task: CTRLTask
    @Environment(\.dismiss) private var dismiss

    enum Step { case context, generating, preview, sent }
    @State private var step: Step = .context
    @State private var showAIConfirm = false

    // Context fields
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
        ("total", "Total", "Plena autonomia"),
        ("supervisado", "Supervisado", "Actualizacion semanal"),
        ("con_aprobacion", "Con aprobacion", "Consulta antes de decidir"),
    ]
    private let tonos = [("formal", "Formal"), ("colaborativo", "Colaborativo"), ("urgente", "Urgente")]

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .context:    contextForm
                case .generating: ProgressView("Generando correo con IA...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .preview:    previewView
                case .sent:       sentConfirmation
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil)
                    }
                }
            }
        }
        .aiUsageAlert(isPresented: $showAIConfirm, title: "Generar correo con IA") {
            Task { await generateEmail() }
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

    // MARK: - Context Form

    private var contextForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    Text("Para: \(task.assignee ?? "Sin asignar")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let due = task.dueDate {
                        Text("Fecha limite: \(due)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Tarea delegada")
            }

            Section("Objetivo vinculado") {
                TextField("Ej: Incrementar ventas Q2...", text: $objetivoVinculado, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Contexto adicional") {
                TextField("Antecedentes que el responsable debe conocer...", text: $contextoAdicional, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Recursos disponibles") {
                TextField("Herramientas, presupuesto, equipo...", text: $recursosDisponibles, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Primer checkpoint (dias)") {
                TextField("Ej: 3, 5, 7", text: $checkpointDias)
                    .keyboardType(.numberPad)
            }

            Section("Nivel de autonomia") {
                ForEach(nivelesAutonomia, id: \.0) { nivel in
                    Button {
                        withAnimation { nivelAutonomia = nivel.0 }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(nivel.1).font(.subheadline).fontWeight(.medium).foregroundStyle(.primary)
                                Text(nivel.2).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if nivelAutonomia == nivel.0 {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ctrlPurple)
                            }
                        }
                    }
                }
            }

            Section("Tono") {
                Picker("Tono", selection: $tono) {
                    ForEach(tonos, id: \.0) { t in Text(t.1).tag(t.0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button { showAIConfirm = true } label: {
                    HStack {
                        Spacer()
                        Label("Generar correo con IA", systemImage: "sparkles").fontWeight(.semibold)
                        Spacer()
                    }
                }
                .listRowBackground(Color.ctrlPurple)
                .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Asunto:").font(.caption).foregroundStyle(.secondary)
                Text(emailSubject).font(.subheadline).fontWeight(.medium)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))

            Divider()
            TextEditor(text: $emailDraft).font(.body).padding(.horizontal, 12).padding(.vertical, 8)
            Divider()

            HStack(spacing: 12) {
                Button { step = .context } label: {
                    Text("Editar contexto").font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button { showAIConfirm = true } label: {
                    Label("Regenerar", systemImage: "arrow.counterclockwise").font(.subheadline)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button { Task { await sendEmail() } } label: {
                    Label("Enviar", systemImage: "paperplane.fill").font(.subheadline.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.ctrlPurple).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
    }

    // MARK: - Sent

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(.green)
            Text("Correo marcado como enviado").font(.headline)
            Text(task.assignee ?? "").font(.subheadline).foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = emailDraft
            } label: {
                Label("Copiar al portapapeles", systemImage: "doc.on.doc")
                    .padding().frame(maxWidth: .infinity)
                    .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.top, 8)
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

        struct EmailBody: Encodable {
            let context: [String: String?]
            let send: Bool
        }

        let ctx: [String: String?] = [
            "objetivo_vinculado": objetivoVinculado.isEmpty ? nil : objetivoVinculado,
            "contexto_adicional": contextoAdicional.isEmpty ? nil : contextoAdicional,
            "recursos_disponibles": recursosDisponibles.isEmpty ? nil : recursosDisponibles,
            "fecha_primer_checkpoint": checkpointStr,
            "nivel_autonomia": nivelAutonomia,
            "tono": tono,
        ]

        do {
            let result: SmartEmailResult = try await APIClient.shared.request(
                .taskPrepareEmail(id: task.id),
                method: "POST",
                body: EmailBody(context: ctx, send: false)
            )
            emailSubject = result.emailSubject
            emailDraft = result.emailDraft
            step = .preview
        } catch {
            step = .context
        }
    }

    private func sendEmail() async {
        struct SendBody: Encodable { let context: [String: String?]; let send: Bool }
        do {
            let _: SmartEmailResult = try await APIClient.shared.request(
                .taskPrepareEmail(id: task.id),
                method: "POST",
                body: SendBody(context: [:], send: true)
            )
            step = .sent
        } catch { }
    }
}
