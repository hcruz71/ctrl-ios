import SwiftUI

struct GmailImportView: View {
    var onAnalyze: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager

    @State private var accounts: [GoogleCalendarAccount] = []
    @State private var isLoadingAccounts = true
    @State private var selectedHours = 72
    @State private var unreadOnly = false
    @State private var excludeNewsletters = false
    @State private var attachmentsOnly = false

    private let periodOptions: [(Int, String)] = [
        (24, "24h"), (48, "48h"), (72, "72h"), (168, "1 sem")
    ]

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
                        ForEach(periodOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(lang.t("emails.filters")) {
                    Toggle(lang.t("emails.unread_only"), isOn: $unreadOnly)
                    Toggle(lang.t("emails.exclude_newsletters"), isOn: $excludeNewsletters)
                    Toggle(lang.t("emails.attachments_only"), isOn: $attachmentsOnly)
                }
            }

            Button {
                onAnalyze(selectedHours)
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text(lang.t("emails.analyze_btn"))
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.ctrlPurple)
                .foregroundColor(.white)
                .cornerRadius(12)
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
}
