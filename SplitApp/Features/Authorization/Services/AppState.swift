import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {

    @Published var isLoading = false
    @Published var isLoggedIn = false

}
