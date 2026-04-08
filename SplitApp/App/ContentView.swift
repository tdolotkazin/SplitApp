import SwiftUI

struct ContentView: View {

    var body: some View {
        BottomTabBarView()
            .task {
                await AppSyncCoordinator.shared.syncOnLaunchIfNeeded()
            }
    }
}

#Preview {
    ContentView()
}
