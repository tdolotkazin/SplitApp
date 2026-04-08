import Foundation
import Combine

@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published private(set) var event: Event?
    @Published private(set) var receipts: [Receipt] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isShowingCachedDataBanner = false

    private let eventId: UUID
    private let service: EventManagementServiceProtocol
    private let receiptsRepository: ReceiptsRepositoryProtocol

    init(
        eventId: UUID,
        service: EventManagementServiceProtocol,
        receiptsRepository: ReceiptsRepositoryProtocol = ReceiptsRepository()
    ) {
        self.eventId = eventId
        self.service = service
        self.receiptsRepository = receiptsRepository
    }

    func load() async {
        errorMessage = nil
        isShowingCachedDataBanner = false

        var hasCachedData = false

        if let cachedEvent = try? await service.cachedEvent(id: eventId) {
            event = cachedEvent
            hasCachedData = true
        }

        if let cachedReceipts = try? await receiptsRepository.getCachedReceipts(eventId: eventId) {
            receipts = cachedReceipts
            hasCachedData = hasCachedData || !cachedReceipts.isEmpty
        }

        isLoading = !hasCachedData

        do {
            async let fetchedEvent = service.refreshEvent(id: eventId)
            async let fetchedReceipts = receiptsRepository.refreshReceipts(eventId: eventId)

            self.event = try await fetchedEvent
            self.receipts = try await fetchedReceipts
        } catch {
            if event == nil && receipts.isEmpty {
                self.errorMessage = error.localizedDescription
            } else {
                self.isShowingCachedDataBanner = true
            }
        }

        isLoading = false
    }
}
