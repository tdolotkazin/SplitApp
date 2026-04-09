import Foundation

struct EmojiPredictModel: Codable, Identifiable, Hashable {
    let emoji: String
    let name: String
    let version: String
    let codePoints: [String]

    var id: String { emoji + name }
}
