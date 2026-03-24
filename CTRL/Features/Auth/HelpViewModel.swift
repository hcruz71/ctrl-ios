import Foundation
import AVFoundation

@MainActor
final class HelpViewModel: ObservableObject {
    @Published var articles: [HelpArticle] = []
    @Published var faqs: [HelpFaq] = []
    @Published var searchResults: HelpSearchResult?
    @Published var selectedCategory = "todos"
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var currentlySpeakingId: String?

    private let synthesizer = AVSpeechSynthesizer()

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

    // MARK: - TTS

    func speakArticle(_ article: HelpArticle) {
        synthesizer.stopSpeaking(at: .immediate)
        let clean = stripMarkdown(article.content)
        let utterance = AVSpeechUtterance(string: "\(article.title). \(clean)")
        configureUtterance(utterance)
        currentlySpeakingId = article.id
        synthesizer.speak(utterance)
    }

    func speakFaq(_ faq: HelpFaq) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: "\(faq.question). \(faq.answer)")
        configureUtterance(utterance)
        currentlySpeakingId = faq.id
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        currentlySpeakingId = nil
    }

    private func configureUtterance(_ utterance: AVSpeechUtterance) {
        let voiceId = UserDefaults.standard.string(forKey: "assistantVoice") ?? "es-MX-female"
        if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage())
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
    }

    private func voiceLanguage() -> String {
        switch lang {
        case "en": return "en-US"
        case "pt": return "pt-BR"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        default:   return "es-MX"
        }
    }

    private func stripMarkdown(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "# ", with: "")
            .replacingOccurrences(of: "- ", with: "")
            .replacingOccurrences(of: "`", with: "")
    }
}
