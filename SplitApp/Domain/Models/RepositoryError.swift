import Foundation

enum RepositoryError: LocalizedError {
    case offlineNoCache
    case unsupportedByBackend
    case notFound

    var errorDescription: String? {
        switch self {
        case .offlineNoCache:
            "Данные недоступны: нет интернета и локального кэша."
        case .unsupportedByBackend:
            "Операция пока не поддерживается backend-контрактом."
        case .notFound:
            "Запрошенная сущность не найдена."
        }
    }
}
