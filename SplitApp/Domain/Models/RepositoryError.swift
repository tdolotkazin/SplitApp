import Foundation

enum RepositoryError: LocalizedError {
    case offlineNoCache
    case unsupportedByBackend
    case notFound

    var errorDescription: String? {
        switch self {
        case .offlineNoCache:
            return "Данные недоступны: нет интернета и локального кэша."
        case .unsupportedByBackend:
            return "Операция пока не поддерживается backend-контрактом."
        case .notFound:
            return "Запрошенная сущность не найдена."
        }
    }
}
