import Foundation

struct Share: Hashable {
    let id: UUID
    let userId: UUID
    let shareValue: Double

    init(id: UUID = UUID(), userId: UUID, shareValue: Double) {
        self.id = id
        self.userId = userId
        self.shareValue = shareValue
    }
}
