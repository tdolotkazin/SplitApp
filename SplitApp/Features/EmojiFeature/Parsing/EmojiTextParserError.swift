import Foundation

enum EmojiTextParserError: Error, LocalizedError {
    case fileNotFound
    case invalidDecoding

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Файл emojis.txt не найден в Bundle (беда бедовая)"
        case .invalidDecoding:
            return "Не удалось прочитать emojis.txt как UTF-8(беда)"
        }
    }
}
