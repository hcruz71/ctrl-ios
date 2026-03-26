import SwiftUI

struct AbsenceDetailView: View {
    let absence: UserAbsence
    var onUpdate: () async -> Void

    @State private var isGenerating = false
    @State private var generatedAbsence: UserAbsence?
    @State private var selectedDocTab = 0
    @State private var showAIConfirm = false

    private var current: UserAbsence { generatedAbsence ?? absence }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text(current.type.capitalized)
                        .font(.title2.bold())
                    Text("\(current.startDate) al \(current.endDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let sub = current.substituteName {
                        Label("Sustituto: \(sub)", systemImage: "person.fill")
                            .font(.subheadline)
                    }
                }
                .padding()

                // Generate button
                if current.documentsGeneratedAt == nil {
                    Button {
                        showAIConfirm = true
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                                Text("Generando documentos...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generar documentos de entrega")
                            }
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ctrlPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)
                }

                // Documents tabs
                if current.documentsGeneratedAt != nil {
                    Picker("Documento", selection: $selectedDocTab) {
                        Text("Memo").tag(0)
                        Text("Comunicado").tag(1)
                        Text("Regreso").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        switch selectedDocTab {
                        case 0:
                            Text("MEMO DE ENTREGA")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(current.handoverDocument ?? "Sin contenido")
                                .font(.body)
                        case 1:
                            Text("COMUNICADO STAKEHOLDERS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(current.stakeholderMessage ?? "Sin contenido")
                                .font(.body)
                        default:
                            Text("PLAN DE REGRESO")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(current.returnPlan ?? "Sin contenido")
                                .font(.body)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Copy button
                    Button {
                        let text: String
                        switch selectedDocTab {
                        case 0:  text = current.handoverDocument ?? ""
                        case 1:  text = current.stakeholderMessage ?? ""
                        default: text = current.returnPlan ?? ""
                        }
                        UIPasteboard.general.string = text
                    } label: {
                        Label("Copiar al portapapeles", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Detalle de ausencia")
        .navigationBarTitleDisplayMode(.inline)
        .aiUsageAlert(isPresented: $showAIConfirm, title: "Generar documentos con IA", estimatedUsage: "2-3") {
            Task { await generateDocuments() }
        }
    }

    private func generateDocuments() async {
        isGenerating = true
        do {
            let result: UserAbsence = try await APIClient.shared.request(
                .generateHandover(id: absence.id), method: "POST"
            )
            generatedAbsence = result
            await onUpdate()
        } catch {
            #if DEBUG
            print("[AbsenceDetail] Generate failed: \(error)")
            #endif
        }
        isGenerating = false
    }
}
