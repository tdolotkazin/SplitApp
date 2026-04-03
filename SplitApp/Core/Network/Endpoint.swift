import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PATCH
    case DELETE
}

enum Endpoint {
    // MARK: - Users
    case createUser

    // MARK: - Events
    case createEvent
    case listEvents(userId: UUID?)
    case getEvent(id: UUID)
    case updateEvent(id: UUID)
    case addParticipants(eventId: UUID)
    case removeParticipant(eventId: UUID, userId: UUID)

    // MARK: - Receipts
    case createReceipt(eventId: UUID)
    case listReceipts(eventId: UUID)
    case updateReceipt(id: UUID)
    case deleteReceipt(id: UUID)

    // MARK: - Balances
    case getBalances(eventId: UUID)

    // MARK: - Payments
    case createPayment(eventId: UUID)
    case listPayments(eventId: UUID)
    case updatePayment(id: UUID)

    // MARK: - Path

    var path: String {
        switch self {
        // Users
        case .createUser:
            return "/api/users"

        // Events
        case .createEvent:
            return "/api/events"
        case .listEvents:
            return "/api/events"
        case .getEvent(let id):
            return "/api/events/\(id.uuidString)"
        case .updateEvent(let id):
            return "/api/events/\(id.uuidString)"
        case .addParticipants(let eventId):
            return "/api/events/\(eventId.uuidString)/participants"
        case .removeParticipant(let eventId, let userId):
            return "/api/events/\(eventId.uuidString)/participants/\(userId.uuidString)"

        // Receipts
        case .createReceipt(let eventId):
            return "/api/events/\(eventId.uuidString)/receipts"
        case .listReceipts(let eventId):
            return "/api/events/\(eventId.uuidString)/receipts"
        case .updateReceipt(let id):
            return "/api/receipts/\(id.uuidString)"
        case .deleteReceipt(let id):
            return "/api/receipts/\(id.uuidString)"

        // Balances
        case .getBalances(let eventId):
            return "/api/events/\(eventId.uuidString)/balances"

        // Payments
        case .createPayment(let eventId):
            return "/api/events/\(eventId.uuidString)/payments"
        case .listPayments(let eventId):
            return "/api/events/\(eventId.uuidString)/payments"
        case .updatePayment(let id):
            return "/api/payments/\(id.uuidString)"
        }
    }

    // MARK: - Method

    var method: HTTPMethod {
        switch self {
        case .createUser, .createEvent, .addParticipants, .createReceipt, .createPayment:
            return .POST
        case .listEvents, .getEvent, .listReceipts, .getBalances, .listPayments:
            return .GET
        case .updateEvent, .updateReceipt, .updatePayment:
            return .PATCH
        case .removeParticipant, .deleteReceipt:
            return .DELETE
        }
    }

    // MARK: - Query Items

    var queryItems: [URLQueryItem]? {
        switch self {
        case .listEvents(let userId):
            guard let userId else { return nil }
            return [URLQueryItem(name: "user_id", value: userId.uuidString)]
        default:
            return nil
        }
    }
}
