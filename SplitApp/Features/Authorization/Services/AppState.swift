import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var isLoading = false
    @Published var isLoggedIn = false

    init(isLoading: Bool = true, isLoggedIn: Bool = false) {
        self.isLoading = isLoading
        self.isLoggedIn = isLoggedIn
    }
}
