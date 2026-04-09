import Foundation

struct CreatePaymentCommand {
    let senderId: UUID
    let receiverId: UUID
    let amount: Double
}

struct UpdatePaymentCommand {
    let confirmed: Bool
}
