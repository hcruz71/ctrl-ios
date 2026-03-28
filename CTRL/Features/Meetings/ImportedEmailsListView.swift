import SwiftUI

struct ImportedEmailsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var lang: LanguageManager

    @State private var emails: [ImportedEmailItem] = []
    @State private var total = 0
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""

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
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(lang.t("emails.imported_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }
    }

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
                if email.hasAttachments == true {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(email.subject ?? "(sin asunto)")
                .font(.subheadline)
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
}
