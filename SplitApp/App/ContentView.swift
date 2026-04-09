import SwiftUI

struct ContentView: View {
    private let dependencies: AppDependencies
    private let appState: AppState

    init(dependencies: AppDependencies, appState: AppState) {
        self.dependencies = dependencies
        self.appState = appState
    }

    var body: some View {
        BottomTabBarView(configuration: BottomTabConfiguration.makeDefault(with: dependencies, appState: appState))
    }
}

#Preview {
    ContentView(dependencies: .preview, appState: AppState(isLoading: false, isLoggedIn: true))
}
