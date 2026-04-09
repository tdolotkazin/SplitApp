import Foundation

enum EventsNavigationRoute: Hashable {
    case scanner
    case billEntry
    case eventPicker
}

enum EventsNavigationAction {
    case scanButtonTapped
    case addButtonTapped
    case scannerCaptureCompleted
    case eventCardTapped
}

struct EventsNavigationRules {
    let scanButtonRoute: EventsNavigationRoute
    let addButtonRoute: EventsNavigationRoute
    let scannerCaptureRoute: EventsNavigationRoute

    let eventCardRoute: EventsNavigationRoute

    init(
        scanButtonRoute: EventsNavigationRoute = .scanner,
        addButtonRoute: EventsNavigationRoute = .billEntry,
        scannerCaptureRoute: EventsNavigationRoute = .billEntry,
        eventCardRoute: EventsNavigationRoute = .eventPicker
    ) {
        self.scanButtonRoute = scanButtonRoute
        self.addButtonRoute = addButtonRoute
        self.scannerCaptureRoute = scannerCaptureRoute
        self.eventCardRoute = eventCardRoute
    }

    func route(for action: EventsNavigationAction) -> EventsNavigationRoute {
        switch action {
        case .scanButtonTapped:
            scanButtonRoute
        case .addButtonTapped:
            addButtonRoute
        case .scannerCaptureCompleted:
            scannerCaptureRoute
        case .eventCardTapped:
            eventCardRoute
        }
    }
}
