import SwiftUI

struct ImportedEmailsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager

    @State private var emails: [ImportedEmailItem] = []
    @State private var total = 0
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var showDeleteAllConfirm = false
    @State private var showMarkAllReadConfirm = false

    private let categories = [
        ("urgente", "flame.fill", Color.red),
        ("requiere_accion", "star.fill", Color.orange),
        ("informativo", "info.circle.fill", Color.blue),
        ("ignorar", "xmark.circle", Color.gray),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(label: lang.t("filter.all"), selected: selectedCategory == nil) {
                            selectedCategory = nil
                            Task { await loadEmails() }
                        }
                        ForEach(categories, id: \.0) { cat, icon, color in
                            filterChip(
                                label: lang.t("emails.\(cat == "requiere_accion" ? "action" : cat)"),
                                icon: icon,
                                color: color,
                                selected: selectedCategory == cat
                            ) {
                                selectedCategory = cat
                                Task { await loadEmails() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if emails.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(lang.t("emails.no_imported"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(emails) { email in
                            emailRow(email)
                                .swipeActions(edge: .trailing) {
                                    if email.source == "gmail" {
                                        Button(role: .destructive) {
                                            Task { await deleteEmail(email.id) }
                                        } label: {
                                            Label(lang.t("common.delete"), systemImage: "trash")
                                        }
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if email.isRead != true {
                                        Button {
                                            Task { await markRead(ids: [email.id]) }
                                        } label: {
                                            Label(lang.t("emails.mark_read"), systemImage: "envelope.open")
                                        }
                                        .tint(.blue)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(lang.t("emails.imported_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Menu {
                        Button {
                            showMarkAllReadConfirm = true
                        } label: {
                            Label(lang.t("emails.mark_all_read"), systemImage: "envelope.open")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showDeleteAllConfirm = true
                        } label: {
                            Label(lang.t("emails.delete_gmail_only"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.t("common.done")) { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: lang.t("emails.search_placeholder"))
            .onSubmit(of: .search) {
                Task { await loadEmails() }
            }
            .task {
                await loadEmails()
            }
            .alert(lang.t("emails.delete_gmail_only"), isPresented: $showDeleteAllConfirm) {
                Button(lang.t("common.delete"), role: .destructive) {
                    Task { await deleteAllGmail() }
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            } message: {
                Text(lang.t("emails.delete_gmail_confirm"))
            }
            .alert(lang.t("emails.mark_all_read"), isPresented: $showMarkAllReadConfirm) {
                Button(lang.t("emails.mark_all_read")) {
                    Task { await markAllRead() }
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            }
        }
    }

    // MARK: - Row

    private func emailRow(_ email: ImportedEmailItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let cat = email.aiCategory {
                    categoryBadge(cat)
                }
                Text(email.sender ?? email.senderEmail ?? "")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                sourceBadge(email.source ?? "gmail")
                if email.hasAttachments == true {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(email.subject ?? "(sin asunto)")
                .font(.subheadline)
                .foregroundStyle(email.isRead == true ? .secondary : .primary)
                .lineLimit(1)
            if let snippet = email.snippet, !snippet.isEmpty {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }

    private func sourceBadge(_ source: String) -> some View {
        Text(source == "gmail" ? "Gmail" : lang.t("emails.source_file"))
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(source == "gmail" ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
            .foregroundStyle(source == "gmail" ? .blue : .secondary)
            .cornerRadius(4)
    }

    private func categoryBadge(_ cat: String) -> some View {
        let (icon, color): (String, Color) = {
            switch cat {
            case "urgente": return ("flame.fill", .red)
            case "requiere_accion": return ("star.fill", .orange)
            case "informativo": return ("info.circle.fill", .blue)
            case "ignorar": return ("xmark.circle", .gray)
            default: return ("circle", .gray)
            }
        }()
        return Image(systemName: icon)
            .font(.caption2)
            .foregroundStyle(color)
    }

    private func filterChip(label: String, icon: String? = nil, color: Color? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundStyle(selected ? .white : (color ?? .primary))
                }
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? Color.ctrlPurple : Color.gray.opacity(0.15))
            .foregroundColor(selected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func loadEmails() async {
        isLoading = true
        let search = searchText.isEmpty ? nil : searchText
        do {
            let page: ImportedEmailsPage = try await APIClient.shared.request(
                .gmailEmails(category: selectedCategory, limit: 100, search: search)
            )
            emails = page.emails
            total = page.total
        } catch {
            emails = []
        }
        isLoading = false
    }

    private func deleteEmail(_ id: String) async {
        try? await APIClient.shared.requestVoid(.gmailEmail(id: id), method: "DELETE")
        emails.removeAll { $0.id == id }
        total = max(0, total - 1)
    }

    private func deleteAllGmail() async {
        try? await APIClient.shared.requestVoid(.gmailEmailsDeleteAll, method: "DELETE")
        await loadEmails()
    }

    private func markRead(ids: [String]) async {
        struct Body: Encodable { let emailIds: [String] }
        try? await APIClient.shared.requestVoid(.gmailEmailsMarkRead, method: "PATCH", body: Body(emailIds: ids))
        for i in emails.indices where ids.contains(emails[i].id) {
            emails[i].isRead = true
        }
    }

    private func markAllRead() async {
        struct Body: Encodable { let all: Bool }
        try? await APIClient.shared.requestVoid(.gmailEmailsMarkRead, method: "PATCH", body: Body(all: true))
        for i in emails.indices {
            emails[i].isRead = true
        }
    }
}
