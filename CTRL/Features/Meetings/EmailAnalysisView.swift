import SwiftUI
import UniformTypeIdentifiers

struct EmailAnalysisView: View {
    @EnvironmentObject var lang: LanguageManager
    @State private var result: EmailAnalysisResult?
    @State private var isLoading = false
    @State private var hasLoaded = false
    @State private var selectedPeriod = 72
    @State private var showImport = false
    @State private var showAIConfirm = false
    @State private var showStats = false

    private let periods = [(24, "24h"), (48, "48h"), (72, "72h")]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period selector
                Picker("Periodo", selection: $selectedPeriod) {
                    ForEach(periods, id: \.0) { p in
                        Text(p.1).tag(p.0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Analyze button
                if !hasLoaded && !isLoading {
                    Button { showAIConfirm = true } label: {
                        Label(lang.t("emails.analyze_btn"), systemImage: "sparkles")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ctrlPurple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Leyendo y analizando correos...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 40)
                } else if let r = result {
                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(r.totalEmails) correos analizados")
                                .font(.subheadline.bold())
                            Spacer()
                            if let period = r.period {
                                Text(period)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(r.analysis)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Categories
                    if let cats = r.categories {
                        categoriesSection(cats)
                    }

                    // Suggested tasks
                    if let tasks = r.suggestedTasks, !tasks.isEmpty {
                        suggestedTasksSection(tasks)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(lang.t("emails.title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { composeEmail() } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showImport = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
                if hasLoaded {
                    Button { showStats = true } label: {
                        Image(systemName: "chart.bar")
                    }
                }
                Button { showAIConfirm = true } label: {
                    Image(systemName: "sparkles")
                }
            }
        }
        .withProfileButton()
        .aiUsageAlert(isPresented: $showAIConfirm, title: "Analizar correos con IA", estimatedUsage: "3-5") {
            Task { await analyzeGmail() }
        }
        .sheet(isPresented: $showImport) {
            MboxImportView { content in
                Task { await analyzeMbox(content) }
            }
        }
        .sheet(isPresented: $showStats) {
            if let r = result {
                EmailStatsSheet(result: r) {
                    result = nil
                    hasLoaded = false
                }
            }
        }
    }

    // MARK: - Compose

    private func composeEmail() {
        if let url = URL(string: "mailto:"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Categories

    private func categoriesSection(_ cats: EmailCategories) -> some View {
        VStack(spacing: 8) {
            categoryRow("Urgente", cats.urgente ?? [], .red, "flame.fill")
            categoryRow("Requiere accion", cats.requiereAccion ?? [], .orange, "star.fill")
            categoryRow("Informativo", cats.informativo ?? [], .blue, "info.circle.fill")
            categoryRow("Ignorar", cats.ignorar ?? [], .gray, "xmark.circle")
        }
        .padding(.horizontal)
    }

    private func categoryRow(_ title: String, _ emails: [EmailSummary], _ color: Color, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(emails.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15), in: Capsule())
                    .foregroundStyle(color)
            }

            if !emails.isEmpty {
                ForEach(emails.prefix(3)) { email in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(email.senderName)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text(email.subject)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Suggested Tasks

    private func suggestedTasksSection(_ tasks: [SuggestedEmailTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tareas sugeridas", systemImage: "checkmark.circle")
                .font(.subheadline.bold())
                .padding(.horizontal)

            ForEach(tasks) { task in
                HStack(spacing: 8) {
                    if let p = task.priority {
                        Text(p)
                            .font(.caption2.bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(priorityColor(p).opacity(0.15))
                            .foregroundStyle(priorityColor(p))
                            .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                        if let from = task.fromEmail {
                            Text("De: \(from)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func analyzeGmail() async {
        isLoading = true
        do {
            result = try await APIClient.shared.request(.gmailAnalyze(hours: selectedPeriod))
        } catch {
            result = EmailAnalysisResult(totalEmails: 0, analysis: error.localizedDescription)
        }
        hasLoaded = true
        isLoading = false
    }

    private func analyzeMbox(_ content: String) async {
        isLoading = true
        struct Body: Encodable { let content: String }
        do {
            result = try await APIClient.shared.request(
                .gmailAnalyzeMbox, method: "POST", body: Body(content: content)
            )
        } catch {
            result = EmailAnalysisResult(totalEmails: 0, analysis: error.localizedDescription)
        }
        hasLoaded = true
        isLoading = false
    }

    private func priorityColor(_ p: String) -> Color {
        switch p {
        case "A": return .red
        case "B": return .orange
        default: return .blue
        }
    }
}

// MARK: - Email Stats Sheet

private struct EmailStatsSheet: View {
    let result: EmailAnalysisResult
    var onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Resumen") {
                    LabeledContent("Total analizados", value: "\(result.totalEmails)")
                    if let p = result.period {
                        LabeledContent("Periodo", value: p)
                    }
                }

                if let cats = result.categories {
                    Section("Por categoria") {
                        HStack {
                            statBadge("Urgente", cats.urgente?.count ?? 0, .red)
                            statBadge("Accion", cats.requiereAccion?.count ?? 0, .orange)
                            statBadge("Info", cats.informativo?.count ?? 0, .blue)
                            statBadge("Ignorar", cats.ignorar?.count ?? 0, .gray)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Limpiar analisis", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Estadisticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .alert("Limpiar analisis", isPresented: $showClearConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Limpiar", role: .destructive) {
                    onClear()
                    dismiss()
                }
            } message: {
                Text("Se eliminara el analisis actual. Podras ejecutar uno nuevo.")
            }
        }
    }

    private func statBadge(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mbox Import View

private struct MboxImportView: View {
    var onImport: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Importar archivo de correo")
                    .font(.headline)

                Text("Selecciona un archivo .mbox o .eml exportado desde tu cliente de correo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    showFilePicker = true
                } label: {
                    Label("Seleccionar archivo", systemImage: "folder")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ctrlPurple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Importar correos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "mbox") ?? .data,
                    UTType(filenameExtension: "eml") ?? .data,
                    .plainText,
                    .data,
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        dismiss()
                        onImport(content)
                    }
                case .failure:
                    break
                }
            }
        }
    }
}
