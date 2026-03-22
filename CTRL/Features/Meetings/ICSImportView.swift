import SwiftUI
import UniformTypeIdentifiers

struct ICSImportView: View {
    @ObservedObject var vm: MeetingsViewModel
    @Environment(\.dismiss) private var dismiss

    enum Step { case pickFile, filters, parsing, selectEvents, importing, done }
    @State private var step: Step = .pickFile

    // File
    @State private var showingPicker = false
    @State private var fileData: Data?
    @State private var fileSize: String = ""

    // Filters
    @State private var dateFilter: ICSDateFilter = .futureOnly
    @State private var keyword = ""
    @State private var excludeAllDay = false
    @State private var excludePastRecurring = true

    // Parsed events
    @State private var allEvents: [ICSEvent] = []
    @State private var selectedIds: Set<UUID> = []
    @State private var parseProgress = ""

    // Import results
    @State private var totalImported = 0
    @State private var totalSkipped = 0
    @State private var importProgress = ""

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .pickFile:    pickFileView
                case .filters:     filtersView
                case .parsing:     parsingView
                case .selectEvents: selectEventsView
                case .importing:   importingView
                case .done:        doneView
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
            .navigationTitle("Importar .ics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPicker) {
                DocumentPickerView { data, size in
                    fileData = data
                    fileSize = size
                    step = .filters
                }
            }
        }
    }

    // MARK: - Step 1: Pick File

    private var pickFileView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Color.ctrlPurple)
            Text("Selecciona un archivo .ics")
                .font(.headline)
            Text("Exportado desde Google Calendar, Outlook, Apple Calendar u otro servicio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showingPicker = true
            } label: {
                Label("Seleccionar archivo", systemImage: "folder")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: 280)
                    .background(Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
        }
    }

    // MARK: - Step 2: Filters

    private var filtersView: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "doc.fill")
                    Text("Archivo seleccionado")
                    Spacer()
                    Text(fileSize)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Rango de fechas") {
                ForEach(ICSDateFilter.allCases) { filter in
                    Button {
                        dateFilter = filter
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if dateFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.ctrlPurple)
                            }
                        }
                    }
                }
            }

            Section("Filtro por palabra clave") {
                TextField("Ej: reunion, junta, proyecto...", text: $keyword)
            }

            Section("Opciones") {
                Toggle("Excluir eventos de todo el dia", isOn: $excludeAllDay)
                Toggle("Excluir eventos recurrentes pasados", isOn: $excludePastRecurring)
            }

            Section {
                Button {
                    Task { await parseFile() }
                } label: {
                    HStack {
                        Spacer()
                        Label("Procesar archivo", systemImage: "wand.and.stars")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .listRowBackground(Color.ctrlPurple)
                .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Step 3: Parsing

    private var parsingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Procesando archivo...")
                .font(.headline)
            Text(parseProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Step 4: Select Events

    private var selectEventsView: some View {
        VStack(spacing: 0) {
            // Header with counts and select all
            HStack {
                Text("\(selectedIds.count) de \(allEvents.count) seleccionados")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(selectedIds.count == allEvents.count ? "Deseleccionar todos" : "Seleccionar todos") {
                    if selectedIds.count == allEvents.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(allEvents.map(\.id))
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Grouped list
            List {
                let grouped = Dictionary(grouping: allEvents, by: \.monthKey)
                    .sorted { $0.key < $1.key }

                ForEach(grouped, id: \.key) { monthKey, events in
                    Section(events.first?.monthLabel ?? monthKey) {
                        ForEach(events) { event in
                            Button {
                                if selectedIds.contains(event.id) {
                                    selectedIds.remove(event.id)
                                } else {
                                    selectedIds.insert(event.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedIds.contains(event.id)
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundStyle(selectedIds.contains(event.id)
                                                         ? Color.ctrlPurple : .secondary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        HStack(spacing: 8) {
                                            Text(event.date)
                                                .font(.caption)
                                            if let time = event.time {
                                                Text(time)
                                                    .font(.caption)
                                            }
                                            if event.isAllDay {
                                                Text("Todo el dia")
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)

            Divider()

            // Import button
            Button {
                Task { await importSelected() }
            } label: {
                Text("Importar \(selectedIds.count) eventos")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedIds.isEmpty ? Color.gray : Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedIds.isEmpty)
            .padding()
        }
    }

    // MARK: - Step 5: Importing

    private var importingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Importando eventos...")
                .font(.headline)
            Text(importProgress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Done

    private var doneView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("\(totalImported) reuniones importadas")
                .font(.headline)
            if totalSkipped > 0 {
                Text("\(totalSkipped) omitidas (ya existian)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Listo") {
                Task {
                    await vm.fetchMeetings()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.ctrlPurple)
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Actions

    private func parseFile() async {
        guard let data = fileData else { return }
        step = .parsing
        parseProgress = "Leyendo archivo..."

        let parser = ICSParser()
        let options = ICSParser.ParseOptions(
            dateFilter: dateFilter,
            keyword: keyword.isEmpty ? nil : keyword,
            excludeAllDay: excludeAllDay,
            excludePastRecurring: excludePastRecurring,
            maxEvents: 500
        )

        let events = await parser.parse(data: data, options: options)

        // DEBUG: log parse results
        print("[ICSImport] Total eventos parseados: \(events.count)")
        for (i, ev) in events.prefix(3).enumerated() {
            print("[ICSImport] Evento[\(i)]: \(ev.title)")
            print("[ICSImport]   fecha: \(ev.date), hora: \(ev.time ?? "nil")")
            print("[ICSImport]   organizer: \(ev.organizer ?? "nil")")
            print("[ICSImport]   attendees: \(ev.attendees.count)")
            for att in ev.attendees {
                print("[ICSImport]     - \(att.name ?? "?") <\(att.email ?? "?")> org=\(att.isOrganizer)")
            }
        }

        allEvents = events
        selectedIds = Set(events.map(\.id))
        parseProgress = "\(events.count) eventos encontrados"

        step = .selectEvents
    }

    private func importSelected() async {
        step = .importing
        totalImported = 0
        totalSkipped = 0

        let selected = allEvents.filter { selectedIds.contains($0.id) }
        let batches = stride(from: 0, to: selected.count, by: 10).map {
            Array(selected[$0..<min($0 + 50, selected.count)])
        }

        for (i, batch) in batches.enumerated() {
            importProgress = "Enviando lote \(i + 1) de \(batches.count)..."

            let events = batch.map { ev in
                ICSImportEventBody(
                    title: ev.title,
                    date: ev.date,
                    time: ev.time,
                    participants: ev.participants,
                    agenda: ev.agenda,
                    organizer: ev.organizer,
                    attendees: ev.attendees.isEmpty ? nil : ev.attendees
                )
            }

            let body = ICSImportBody(events: events)
            do {
                let result: ICSImportResult = try await APIClient.shared.request(
                    .importICS, method: "POST", body: body
                )
                totalImported += result.imported
                totalSkipped += result.skipped
            } catch {
                print("[ICSImport] Batch \(i + 1) failed: \(error)")
            }
        }

        step = .done
    }
}

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    var onPick: (Data, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types = [UTType(filenameExtension: "ics") ?? .data]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (Data, String) -> Void
        init(onPick: @escaping (Data, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else { return }
            let bytes = data.count
            let sizeStr: String
            if bytes > 1_000_000 {
                sizeStr = String(format: "%.1f MB", Double(bytes) / 1_000_000)
            } else {
                sizeStr = String(format: "%.0f KB", Double(bytes) / 1_000)
            }
            onPick(data, sizeStr)
        }
    }
}
