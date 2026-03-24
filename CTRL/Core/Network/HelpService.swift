import Foundation

@MainActor
final class HelpServiceClient: ObservableObject {
    static let shared = HelpServiceClient()

    @Published var articles: [HelpArticle] = []
    @Published var faqs: [HelpFaq] = []
    @Published var categories: [String] = []
    @Published var isLoading = false

    private var cache: [String: [HelpArticle]] = [:]

    private var lang: String {
        LanguageManager.shared.currentLanguage
    }

    func fetchArticles(category: String? = nil) async {
        let cacheKey = "\(lang)_\(category ?? "all")"
        if let cached = cache[cacheKey] {
            articles = cached
            return
        }

        isLoading = true
        do {
            articles = try await APIClient.shared.request(.helpArticles(lang: lang, category: category))
            cache[cacheKey] = articles
        } catch {
            articles = []
        }
        isLoading = false
    }

    func fetchArticle(id: String) async -> HelpArticle? {
        do {
            return try await APIClient.shared.request(.helpArticle(id: id, lang: lang))
        } catch {
            return nil
        }
    }

    func fetchFaqs(category: String? = nil) async {
        isLoading = true
        do {
            faqs = try await APIClient.shared.request(.helpFaqs(lang: lang, category: category))
        } catch {
            faqs = []
        }
        isLoading = false
    }

    func search(query: String) async -> HelpSearchResult {
        do {
            return try await APIClient.shared.request(.helpSearch(lang: lang, query: query))
        } catch {
            return HelpSearchResult(articles: [], faqs: [])
        }
    }

    func fetchCategories() async {
        do {
            categories = try await APIClient.shared.request(.helpCategories)
        } catch {
            categories = []
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}
