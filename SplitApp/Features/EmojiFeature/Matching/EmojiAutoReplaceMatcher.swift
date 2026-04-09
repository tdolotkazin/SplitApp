import Foundation

final class EmojiAutoReplaceMatcher {
    private let exactIndex: [String: EmojiPredictModel]

    init(emojis: [EmojiPredictModel]) {
        var index: [String: EmojiPredictModel] = [:]

        for emoji in emojis {
            let key = Self.normalize(emoji.name)
            if index[key] == nil {
                index[key] = emoji
            }
        }
        self.exactIndex = index
    }

    func match(for word: String) -> EmojiPredictModel? {
        let normalized = Self.normalize(word)
        guard !normalized.isEmpty else { return nil }

        if let exact = exactIndex[normalized] {
            return exact
        }

        if let englishName = EmojiRussianAliases.map[normalized] {
            let englishKey = Self.normalize(englishName)
            return exactIndex[englishKey]
        }
        return nil
    }

    private static func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
            .lowercased()
    }
}
