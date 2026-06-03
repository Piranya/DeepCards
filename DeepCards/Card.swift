import SwiftData

@Model
final class Card {
    var id: String
    var category: String
    var language1: String?
    var text1: String?
    var language2: String?
    var text2: String?
    var language3: String?
    var text3: String?

    init(
        id: String,
        category: String,
        language1: String? = nil,
        text1: String? = nil,
        language2: String? = nil,
        text2: String? = nil,
        language3: String? = nil,
        text3: String? = nil
    ) {
        self.id = id
        self.category = category
        self.language1 = language1
        self.text1 = text1
        self.language2 = language2
        self.text2 = text2
        self.language3 = language3
        self.text3 = text3
    }
    
    var bestLanguageText: (language: String, text: String)? {
        if let lang = language1, let txt = text1, !txt.isEmpty {
            return (lang, txt)
        }
        if let lang = language2, let txt = text2, !txt.isEmpty {
            return (lang, txt)
        }
        if let lang = language3, let txt = text3, !txt.isEmpty {
            return (lang, txt)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case language1
        case text1
        case language2
        case text2
        case language3
        case text3
    }
}
