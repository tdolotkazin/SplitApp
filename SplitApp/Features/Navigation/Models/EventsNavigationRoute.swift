import Foundation

enum EventsNavigationRoute: Hashable {
    case scanner
    case eventDetail(UUID)
}

struct BillEntryDestination: Identifiable {
    let id = UUID()
    let mode: BillViewModel.Mode

    static func create(eventId: UUID?, scannedItems: [BillItem] = []) -> BillEntryDestination {
        BillEntryDestination(mode: .create(eventId: eventId, scannedItems: scannedItems))
    }

    static func edit(eventId: UUID, receiptId: UUID) -> BillEntryDestination {
        BillEntryDestination(mode: .edit(eventId: eventId, receiptId: receiptId))
    }
}

enum EventsNavigationAction: Equatable {
    case scanButtonTapped
    case addButtonTapped
    case scannerCaptureCompleted
    case eventRowTapped(UUID)
    case addReceiptTapped(UUID)
    case receiptTapped(eventId: UUID, receiptId: UUID)
}

struct EventsNavigationRules {
    let scanButtonRoute: EventsNavigationRoute

    init(
        scanButtonRoute: EventsNavigationRoute = .scanner
    ) {
        self.scanButtonRoute = scanButtonRoute
    }

    func route(for action: EventsNavigationAction) -> EventsNavigationRoute? {
        switch action {
        case .scanButtonTapped:
            return scanButtonRoute
        case .eventRowTapped(let id):
            return .eventDetail(id)
        case .addButtonTapped, .scannerCaptureCompleted, .addReceiptTapped, .receiptTapped:
            return nil
        }
    }
}
