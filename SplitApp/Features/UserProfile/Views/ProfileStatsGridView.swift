import SwiftUI

struct ProfileStatsGridView: View {
    let items: [StatItemModel]

    private let colums = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: colums, spacing: 16) {
            ForEach(items) {
                item in StatCardView(item: item)
            }
        }
    }
}

