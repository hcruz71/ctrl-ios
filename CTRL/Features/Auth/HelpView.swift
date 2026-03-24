import SwiftUI

struct HelpView: View {
    @EnvironmentObject var lang: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HelpViewModel()

    private let categories: [(key: String, label: String, icon: String)] = [
        ("todos", "Todos", "square.grid.2x2"),
        ("objetivos", "Objetivos", "target"),
        ("tareas", "Tareas", "checkmark.circle"),
        ("reuniones", "Reuniones", "calendar"),
        ("proyectos", "Proyectos", "folder"),
        ("contactos", "Contactos", "person.2"),
        ("asistente", "Asistente", "sparkles"),
        ("metodologia", "Metodologia", "book.fill"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(lang.t("action.search"), text: $vm.searchQuery)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onSubmit { Task { await vm.search() } }
                    if !vm.searchQuery.isEmpty {
                        Button { vm.clearSearch() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top, 8)

                // Category tabs
                if vm.searchResults == nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.key) { cat in
                                Button {
                                    withAnimation { vm.selectedCategory = cat.key }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.caption2)
                                        Text(cat.label)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(vm.selectedCategory == cat.key ? Color.ctrlPurple : Color(.systemGray5))
                                    .foregroundStyle(vm.selectedCategory == cat.key ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // Content
                if vm.isLoading && vm.articles.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if vm.filteredArticles.isEmpty && vm.filteredFaqs.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(vm.searchResults != nil ? "Sin resultados" : lang.t("help.coming_soon"))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        if !vm.filteredArticles.isEmpty {
                            Section("Articulos") {
                                ForEach(vm.filteredArticles) { article in
                                    NavigationLink {
                                        HelpArticleDetailView(article: article)
                                    } label: {
                                        HelpArticleRow(article: article)
                                    }
                                }
                            }
                        }

                        if !vm.filteredFaqs.isEmpty {
                            Section("Preguntas frecuentes") {
                                ForEach(vm.filteredFaqs) { faq in
                                    DisclosureGroup {
                                        Text(faq.answer)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .padding(.vertical, 4)
                                    } label: {
                                        Text(faq.question)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(lang.t("help.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lang.t("action.close")) { dismiss() }
                }
            }
            .task { await vm.loadContent() }
            .onChange(of: vm.searchQuery) { _ in
                Task { await vm.search() }
            }
        }
    }
}

// MARK: - Article Row

private struct HelpArticleRow: View {
    let article: HelpArticle

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon)
                .foregroundStyle(Color.ctrlPurple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.subheadline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(article.category.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let type = article.articleType, type != "reference" {
                        Text(typeLabel)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.ctrlPurple.opacity(0.1))
                            .foregroundStyle(Color.ctrlPurple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var categoryIcon: String {
        switch article.category {
        case "objetivos":   return "target"
        case "tareas":      return "checkmark.circle"
        case "reuniones":   return "calendar"
        case "proyectos":   return "folder"
        case "contactos":   return "person.2"
        case "asistente":   return "sparkles"
        case "metodologia": return "book.fill"
        default:            return "doc.text"
        }
    }

    private var typeLabel: String {
        switch article.articleType {
        case "tutorial":    return "Tutorial"
        case "methodology": return "Metodologia"
        default:            return "Referencia"
        }
    }
}

// MARK: - Article Detail

struct HelpArticleDetailView: View {
    let article: HelpArticle
    @State private var showShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(article.category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ctrlPurple.opacity(0.1))
                        .foregroundStyle(Color.ctrlPurple)
                        .clipShape(Capsule())

                    if let type = article.articleType, type != "reference" {
                        Text(type.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Text(LocalizedStringKey(article.content))
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding()
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShare) {
            HelpShareSheet(items: ["\(article.title)\n\n\(article.content)"])
        }
    }
}

private struct HelpShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
