import Foundation

enum EventsNavigationRoute: Hashable {
    case scanner
    case eventPicker
}

struct BillEntryDestination: Identifiable {
    let id = UUID()
    let mode: BillViewModel.Mode

    static func create(
        eventId: UUID?,
        scannedItems: [BillItem] = [],
        receiptImageJPEGData: Data? = nil
    ) -> BillEntryDestination {
        BillEntryDestination(
            mode: .create(
                eventId: eventId,
                scannedItems: scannedItems,
                receiptImageJPEGData: receiptImageJPEGData
            )
        )
    }

    static func edit(eventId: UUID, receiptId: UUID) -> BillEntryDestination {
        BillEntryDestination(mode: .edit(eventId: eventId, receiptId: receiptId))
    }
}

enum EventsNavigationAction: Equatable {
    case scanButtonTapped
    case addButtonTapped
    case scannerCaptureCompleted
    case currentEventTapped
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
        case .currentEventTapped:
            return .eventPicker
        case .addButtonTapped, .scannerCaptureCompleted, .receiptTapped:
            return nil
        }
    }
}
