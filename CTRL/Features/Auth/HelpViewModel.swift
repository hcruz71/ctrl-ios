import Foundation

@MainActor
final class HelpViewModel: ObservableObject {
    @Published var articles: [HelpArticle] = []
    @Published var faqs: [HelpFaq] = []
    @Published var searchResults: HelpSearchResult?
    @Published var selectedCategory = "todos"
    @Published var searchQuery = ""
    @Published var isLoading = false

    private var lang: String {
        LanguageManager.shared.currentLanguage
    }

    var filteredArticles: [HelpArticle] {
        if let results = searchResults {
            return results.articles
        }
        if selectedCategory == "todos" {
            return articles
        }
        return articles.filter { $0.category == selectedCategory }
    }

    var filteredFaqs: [HelpFaq] {
        if let results = searchResults {
            return results.faqs
        }
        if selectedCategory == "todos" {
            return faqs
        }
        return faqs.filter { $0.category == selectedCategory }
    }

    func loadContent() async {
        isLoading = true
        async let a = HelpServiceClient.shared.fetchArticles()
        async let f = HelpServiceClient.shared.fetchFaqs()
        _ = await (a, f)
        articles = HelpServiceClient.shared.articles
        faqs = HelpServiceClient.shared.faqs
        isLoading = false
    }

    func search() async {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else {
            searchResults = nil
            return
        }
        isLoading = true
        searchResults = await HelpServiceClient.shared.search(query: q)
        isLoading = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = nil
    }
}
