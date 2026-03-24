import Foundation

struct HelpArticle: Codable, Identifiable {
    let id: String
    var category: String
    var subcategory: String?
    var title: String
    var content: String
    var articleType: String?
    var persona: String?
    var orderIndex: Int?
}

struct HelpFaq: Codable, Identifiable {
    let id: String
    var category: String
    var question: String
    var answer: String
    var orderIndex: Int?
}

struct HelpSearchResult: Codable {
    var articles: [HelpArticle]
    var faqs: [HelpFaq]
}
