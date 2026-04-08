import SwiftUI

struct BottomTabBarView: View {
    private let configuration: BottomTabConfiguration
    @State private var selectedTab: BottomTabID

    init(configuration: BottomTabConfiguration = .default) {
        self.configuration = configuration
        _selectedTab = State(initialValue: configuration.initialTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(configuration.items) { item in
                item.makeView()
                    .tabItem {
                        Label(item.title, systemImage: item.systemImage)
                    }
                    .tag(item.id)
            }
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    BottomTabBarView()
}
