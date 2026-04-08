import Foundation
import Combine

final class AppState: ObservableObject {
    
    @Published var isLoading = true
    @Published var isLoggedIn = false

    init(isLoading: Bool = true, isLoggedIn: Bool = false) {
        self.isLoading = isLoading
        self.isLoggedIn = isLoggedIn
    }

}
