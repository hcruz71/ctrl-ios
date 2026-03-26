import SwiftUI

struct TaskEmailSheet: View {
    let task: CTRLTask
    @Environment(\.dismiss) private var dismiss

    enum Step { case context, generating, preview, sent }
    @State private var step: Step = .context
    @State private var showAIConfirm = false

    // Contact info
    @State private var contact: Contact?
    @State private var contactLoading = true
    @State private var recipientName = ""
    @State private var recipientEmail = ""

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

    // Mail sending
    @State private var showShareSheet = false
    @State private var shareContent = ""
    @State private var copiedToast = false

    private let nivelesAutonomia = [
        ("total", "Total", "Plena autonomia"),
        ("supervisado", "Supervisado", "Actualizacion semanal"),
        ("con_aprobacion", "Con aprobacion", "Consulta antes de decidir"),
    ]
    private let tonos = [("formal", "Formal"), ("colaborativo", "Colaborativo"), ("urgente", "Urgente")]

    private var hasEmail: Bool { !recipientEmail.isEmpty }

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
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: [shareContent])
        }
        .task { await loadContact() }
    }

    private var navigationTitle: String {
        switch step {
        case .context:    return "Contexto del correo"
        case .generating: return "Generando..."
        case .preview:    return "Vista previa"
        case .sent:       return "Enviado"
        }
    }

    // MARK: - Load Contact

    private func loadContact() async {
        recipientName = task.assignee ?? ""
        #if DEBUG
        print("[TaskEmail] assigneeContactId: \(task.assigneeContactId?.uuidString ?? "nil"), assignee: \(task.assignee ?? "nil")")
        #endif
        guard let contactId = task.assigneeContactId else {
            contactLoading = false
            return
        }
        do {
            let c: Contact = try await APIClient.shared.request(.contact(id: contactId))
            contact = c
            recipientName = c.name
            recipientEmail = c.email ?? ""
            #if DEBUG
            print("[TaskEmail] Contact loaded: \(c.name), email: \(c.email ?? "nil")")
            #endif
        } catch {
            #if DEBUG
            print("[TaskEmail] Contact load error: \(error)")
            #endif
        }
        contactLoading = false
    }

    // MARK: - Context Form

    private var contextForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    HStack {
                        Text("Para: \(recipientName.isEmpty ? "Sin asignar" : recipientName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if contactLoading {
                            ProgressView().controlSize(.small)
                        }
                    }
                    if hasEmail {
                        Label(recipientEmail, systemImage: "envelope")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if let due = task.dueDate {
                        Text("Fecha limite: \(due)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !contactLoading && !hasEmail {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Sin email registrado. Agregalo en los datos del contacto para poder enviar.")
                            .font(.caption)
                            .foregroundStyle(.orange)
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
                TextField("Antecedentes...", text: $contextoAdicional, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Recursos disponibles") {
                TextField("Herramientas, presupuesto...", text: $recursosDisponibles, axis: .vertical)
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
                if hasEmail {
                    HStack {
                        Text("Para:").font(.caption).foregroundStyle(.secondary)
                        Text(recipientEmail).font(.caption).foregroundStyle(.blue)
                    }
                }
                HStack {
                    Text("Asunto:").font(.caption).foregroundStyle(.secondary)
                    Text(emailSubject).font(.subheadline).fontWeight(.medium)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGroupedBackground))

            Divider()
            TextEditor(text: $emailDraft).font(.body).padding(.horizontal, 12).padding(.vertical, 8)
            Divider()

            HStack(spacing: 12) {
                Button { step = .context } label: {
                    Text("Editar").font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    UIPasteboard.general.string = emailDraft
                } label: {
                    Label("Copiar", systemImage: "doc.on.doc").font(.subheadline)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color(.systemGray5)).clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button { sendAction() } label: {
                    Label(hasEmail ? "Enviar" : "Compartir", systemImage: hasEmail ? "paperplane.fill" : "square.and.arrow.up")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.ctrlPurple).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
        }
    }

    // MARK: - Sent

    private var sentConfirmation: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(.green)
            Text("Correo enviado").font(.headline)
            if hasEmail {
                Text(recipientEmail).font(.subheadline).foregroundStyle(.blue)
            } else {
                Text(recipientName).font(.subheadline).foregroundStyle(.secondary)
            }

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

    private func sendAction() {
        if hasEmail {
            // Build mailto: URL — opens Gmail, Outlook, or default mail app
            let subjectEncoded = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = emailDraft.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let mailtoString = "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"

            if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        Task { await markAsSent() }
                    }
                }
            } else {
                // Fallback: share sheet
                shareContent = "Para: \(recipientEmail)\nAsunto: \(emailSubject)\n\n\(emailDraft)"
                showShareSheet = true
            }
        } else {
            shareContent = "Asunto: \(emailSubject)\n\n\(emailDraft)"
            showShareSheet = true
        }
    }

    private func markAsSent() async {
        let body = UpdateTaskBody(emailSentAt: ISO8601DateFormatter().string(from: Date()))
        do {
            let _: CTRLTask = try await APIClient.shared.request(
                .task(id: task.id), body: body
            )
        } catch { }
        step = .sent
    }

    private func generateEmail() async {
        step = .generating

        let checkpointStr: String? = {
            guard let dias = Int(checkpointDias), dias > 0 else { return nil }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df.string(from: Calendar.current.date(byAdding: .day, value: dias, to: Date())!)
        }()

        struct Body: Encodable {
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
                body: Body(context: ctx, send: false)
            )
            emailSubject = result.emailSubject
            emailDraft = result.emailDraft
            if let email = result.contactEmail, !email.isEmpty {
                recipientEmail = email
            }
            if let name = result.contactName, !name.isEmpty {
                recipientName = name
            }
            step = .preview
        } catch {
            step = .context
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
