import Foundation

enum EventsNavigationRoute: Hashable {
    case scanner
    case billEntry
}

enum EventsNavigationAction {
    case scanButtonTapped
    case addButtonTapped
    case scannerCaptureCompleted
}

struct EventsNavigationRules {
    let scanButtonRoute: EventsNavigationRoute
    let addButtonRoute: EventsNavigationRoute
    let scannerCaptureRoute: EventsNavigationRoute

    init(
        scanButtonRoute: EventsNavigationRoute = .scanner,
        addButtonRoute: EventsNavigationRoute = .billEntry,
        scannerCaptureRoute: EventsNavigationRoute = .billEntry
    ) {
        self.scanButtonRoute = scanButtonRoute
        self.addButtonRoute = addButtonRoute
        self.scannerCaptureRoute = scannerCaptureRoute
    }

    func route(for action: EventsNavigationAction) -> EventsNavigationRoute {
        switch action {
        case .scanButtonTapped:
            scanButtonRoute
        case .addButtonTapped:
            addButtonRoute
        case .scannerCaptureCompleted:
            scannerCaptureRoute
        }
    }
}
