import Foundation

enum EmojiTextParserError: Error, LocalizedError {
    case fileNotFound
    case invalidDecoding

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "Файл emojis.txt не найден в Bundle (беда бедовая)"
        case .invalidDecoding:
            "Не удалось прочитать emojis.txt как UTF-8(беда)"
        }
    }
}
