import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        BottomTabBarView(appState: appState)
    }
}

#Preview {
    ContentView()
}
