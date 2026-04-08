import SwiftUI

struct ContentView: View {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var body: some View {
        BottomTabBarView(configuration: .makeDefault(with: dependencies))
    }
}

#Preview {
    ContentView(dependencies: .preview)
}
