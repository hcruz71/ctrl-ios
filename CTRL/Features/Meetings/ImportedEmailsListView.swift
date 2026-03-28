import SwiftUI

struct ImportedEmailsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager

    @State private var emails: [ImportedEmailItem] = []
    @State private var total = 0
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var hasMore = true
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var showDeleteAllConfirm = false
    @State private var showMarkAllReadConfirm = false
    @State private var counts: [String: Int] = [:]

    private let pageSize = 50

    private let categories = [
        ("urgente", "flame.fill", Color.red),
        ("requiere_accion", "star.fill", Color.orange),
        ("informativo", "info.circle.fill", Color.blue),
        ("ignorar", "xmark.circle", Color.gray),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter with counts
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(
                            label: chipLabel("filter.all", count: counts["total"]),
                            selected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                            Task { await resetAndLoad() }
                        }
                        ForEach(categories, id: \.0) { cat, icon, color in
                            filterChip(
                                label: chipLabel("emails.\(cat == "requiere_accion" ? "action" : cat)", count: counts[cat]),
                                icon: icon,
                                color: color,
                                selected: selectedCategory == cat
                            ) {
                                selectedCategory = cat
                                Task { await resetAndLoad() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                if isLoading && emails.isEmpty {
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
                                .listRowBackground(email.isRead != true ? Color.blue.opacity(0.03) : Color.clear)
                                .onAppear {
                                    if email.id == emails.last?.id && hasMore {
                                        Task { await loadMore() }
                                    }
                                }
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

                        if isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
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
                            Label(markReadButtonLabel, systemImage: "envelope.open")
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
                Task { await resetAndLoad() }
            }
            .task {
                async let countsTask: () = loadCounts()
                async let emailsTask: () = loadEmails()
                _ = await (countsTask, emailsTask)
            }
            .alert(lang.t("emails.delete_gmail_only"), isPresented: $showDeleteAllConfirm) {
                Button(lang.t("common.delete"), role: .destructive) {
                    Task { await deleteAllGmail() }
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            } message: {
                Text(lang.t("emails.delete_gmail_confirm"))
            }
            .alert(markReadButtonLabel, isPresented: $showMarkAllReadConfirm) {
                Button(markReadButtonLabel) {
                    Task { await markReadForCurrentFilter() }
                }
                Button(lang.t("common.cancel"), role: .cancel) {}
            }
        }
    }

    // MARK: - Helpers

    private var markReadButtonLabel: String {
        if let cat = selectedCategory {
            let catName = lang.t("emails.\(cat == "requiere_accion" ? "action" : cat)")
            return lang.t("emails.mark_category_read").replacingOccurrences(of: "{category}", with: catName)
        }
        return lang.t("emails.mark_all_read")
    }

    private func chipLabel(_ key: String, count: Int?) -> String {
        let label = lang.t(key)
        if let c = count, c > 0 { return "\(label) (\(c))" }
        return label
    }

    // MARK: - Row

    private func emailRow(_ email: ImportedEmailItem) -> some View {
        let unread = email.isRead != true

        return HStack(spacing: 8) {
            if unread {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let cat = email.aiCategory {
                        categoryBadge(cat)
                    }
                    Text(email.sender ?? email.senderEmail ?? "")
                        .font(.subheadline)
                        .fontWeight(unread ? .bold : .regular)
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
                    .fontWeight(unread ? .semibold : .regular)
                    .foregroundStyle(unread ? .primary : .secondary)
                    .lineLimit(1)
                if let snippet = email.snippet, !snippet.isEmpty {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
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

    private func loadCounts() async {
        if let result: [String: Int] = try? await APIClient.shared.request(.gmailEmailsCounts) {
            counts = result
        }
    }

    private func resetAndLoad() async {
        emails = []
        hasMore = true
        await loadEmails()
    }

    private func loadEmails() async {
        isLoading = true
        let search = searchText.isEmpty ? nil : searchText
        do {
            let page: ImportedEmailsPage = try await APIClient.shared.request(
                .gmailEmails(category: selectedCategory, limit: pageSize, offset: 0, search: search)
            )
            emails = page.emails
            total = page.total
            hasMore = page.emails.count >= pageSize && emails.count < total
        } catch {
            emails = []
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        let search = searchText.isEmpty ? nil : searchText
        do {
            let page: ImportedEmailsPage = try await APIClient.shared.request(
                .gmailEmails(category: selectedCategory, limit: pageSize, offset: emails.count, search: search)
            )
            emails.append(contentsOf: page.emails)
            total = page.total
            hasMore = page.emails.count >= pageSize && emails.count < total
        } catch {}
        isLoadingMore = false
    }

    private func deleteEmail(_ id: String) async {
        try? await APIClient.shared.requestVoid(.gmailEmail(id: id), method: "DELETE")
        emails.removeAll { $0.id == id }
        total = max(0, total - 1)
        NotificationCenter.default.post(name: .emailsChanged, object: nil)
    }

    private func deleteAllGmail() async {
        try? await APIClient.shared.requestVoid(.gmailEmailsDeleteAll, method: "DELETE")
        NotificationCenter.default.post(name: .emailsChanged, object: nil)
        counts = [:]
        await loadCounts()
        await resetAndLoad()
    }

    private func markRead(ids: [String]) async {
        struct Body: Encodable { let emailIds: [String] }
        try? await APIClient.shared.requestVoid(.gmailEmailsMarkRead, method: "PATCH", body: Body(emailIds: ids))
        for i in emails.indices where ids.contains(emails[i].id) {
            emails[i].isRead = true
        }
    }

    private func markReadForCurrentFilter() async {
        if let cat = selectedCategory {
            struct Body: Encodable { let category: String }
            try? await APIClient.shared.requestVoid(.gmailEmailsMarkRead, method: "PATCH", body: Body(category: cat))
        } else {
            struct Body: Encodable { let all: Bool }
            try? await APIClient.shared.requestVoid(.gmailEmailsMarkRead, method: "PATCH", body: Body(all: true))
        }
        for i in emails.indices {
            emails[i].isRead = true
        }
    }
}
