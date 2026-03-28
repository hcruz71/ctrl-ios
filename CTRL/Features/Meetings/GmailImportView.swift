import SwiftUI

struct GmailImportView: View {
    var onAnalyze: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager

    @State private var accounts: [GoogleCalendarAccount] = []
    @State private var isLoadingAccounts = true
    @State private var selectedHours = 72
    @State private var selectedMaxResults = 50
    @State private var unreadOnly = false
    @State private var excludeNewsletters = false
    @State private var forceReimport = false

    // Import state
    @State private var isImporting = false
    @State private var importResult: GmailImportResult?
    @State private var importError: String?

    // Error alert state
    @State private var showScopeError = false
    @State private var showGenericError = false
    @State private var genericErrorMessage = ""

    // Analyze state
    @State private var showAIConfirm = false

    private var periodOptions: [(Int, String)] {
        [
            (24, "24h"),
            (48, "48h"),
            (72, "72h"),
            (168, lang.t("emails.period_week")),
            (720, lang.t("emails.period_month")),
            (2160, lang.t("emails.period_3months")),
            (0, lang.t("emails.period_all")),
        ]
    }

    var connectedEmail: String? {
        accounts.first(where: { $0.isActive })?.email
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoadingAccounts {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if connectedEmail != nil {
                    connectedContent
                } else {
                    notConnectedContent
                }
            }
            .navigationTitle(lang.t("emails.import_gmail"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.t("common.cancel")) { dismiss() }
                }
            }
            .task {
                do {
                    accounts = try await APIClient.shared.request(.googleCalendarAccounts)
                } catch {
                    accounts = []
                }
                isLoadingAccounts = false
            }
            .aiUsageAlert(isPresented: $showAIConfirm, title: lang.t("emails.analyze_btn"), estimatedUsage: "3-5") {
                onAnalyze(selectedHours)
            }
            .alert(lang.t("gmail.error.reconnect_title"), isPresented: $showScopeError) {
                Button(lang.t("gmail.error.go_settings")) {
                    dismiss()
                    NotificationCenter.default.post(name: .init("navigateToSettings"), object: nil)
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            } message: {
                Text(lang.t("gmail.error.reconnect_msg"))
            }
            .alert(lang.t("gmail.error.import_error_title"), isPresented: $showGenericError) {
                Button(lang.t("gmail.error.retry")) {
                    Task { await importEmails() }
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            } message: {
                Text(genericErrorMessage)
            }
        }
    }

    // MARK: - Connected

    private var connectedContent: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.ctrlPurple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t("emails.connected_account"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(connectedEmail ?? "")
                                .font(.subheadline.bold())
                        }
                    }
                }

                Section(lang.t("emails.period")) {
                    Picker(lang.t("emails.period"), selection: $selectedHours) {
                        ForEach(periodOptions, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                }

                Section(lang.t("emails.max_results")) {
                    Picker(lang.t("emails.max_results"), selection: $selectedMaxResults) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                    }
                    .pickerStyle(.segmented)
                }

                Section(lang.t("emails.filters")) {
                    Toggle(lang.t("emails.unread_only"), isOn: $unreadOnly)
                    Toggle(lang.t("emails.exclude_newsletters"), isOn: $excludeNewsletters)
                    Toggle(lang.t("emails.force_reimport"), isOn: $forceReimport)
                }

                Section {
                    Label(lang.t("emails.gmail_sync_note"), systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Import result
                if let result = importResult {
                    Section(lang.t("emails.import_result")) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(lang.t("emails.import_success")
                                .replacingOccurrences(of: "{count}", with: "\(result.imported)"))
                                .font(.subheadline)
                        }
                        if let totalFound = result.totalFound {
                            LabeledContent(lang.t("emails.total_found"), value: "\(totalFound)")
                                .font(.caption)
                        }
                        if result.skipped > 0 {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.secondary)
                                Text(lang.t("emails.import_skipped")
                                    .replacingOccurrences(of: "{count}", with: "\(result.skipped)"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let bd = result.skippedBreakdown {
                            if (bd.duplicate ?? 0) > 0 {
                                Label("\(bd.duplicate ?? 0) \(lang.t("emails.skip.duplicate"))", systemImage: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let error = importError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            // Action buttons
            VStack(spacing: 10) {
                // Step 1: Import
                Button {
                    Task { await importEmails() }
                } label: {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "envelope.arrow.triangle.branch")
                        }
                        Text(isImporting ? lang.t("emails.importing") : lang.t("emails.import_btn"))
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isImporting ? Color.gray : Color.ctrlPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isImporting)

                // Step 2: Analyze with AI
                Button {
                    showAIConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(lang.t("emails.analyze_btn"))
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(importResult != nil ? Color.ctrlPurple : Color.gray.opacity(0.3))
                    .foregroundColor(importResult != nil ? .white : .secondary)
                    .cornerRadius(12)
                }
                .disabled(importResult == nil)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Not Connected

    private var notConnectedContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(lang.t("emails.no_gmail_connected"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                dismiss()
                NotificationCenter.default.post(
                    name: .init("navigateToSettings"), object: nil
                )
            } label: {
                Label(lang.t("emails.go_settings"), systemImage: "gear")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.ctrlPurple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func importEmails() async {
        isImporting = true
        importError = nil
        importResult = nil
        let body = GmailImportBody(
            hours: selectedHours,
            maxResults: selectedMaxResults,
            unreadOnly: unreadOnly ? true : nil,
            excludeNewsletters: excludeNewsletters ? true : nil,
            forceReimport: forceReimport ? true : nil,
            ignoreDate: selectedHours == 0 ? true : nil
        )
        do {
            importResult = try await APIClient.shared.request(.gmailImport, method: "POST", body: body)
        } catch let apiError as APIError {
            let msg = apiError.localizedDescription
            if msg.contains("GMAIL_SCOPE_ERROR") {
                showScopeError = true
            } else if msg.contains("GMAIL_API_DISABLED") {
                genericErrorMessage = lang.t("gmail.error.unavailable_msg")
                showGenericError = true
            } else {
                genericErrorMessage = lang.t("gmail.error.generic_msg")
                showGenericError = true
            }
        } catch {
            genericErrorMessage = lang.t("gmail.error.generic_msg")
            showGenericError = true
        }
        isImporting = false
    }
}
