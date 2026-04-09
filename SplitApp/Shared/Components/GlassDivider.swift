import SwiftUI

struct GlassDivider: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                AppTheme.dividerHighlight,
                Color.clear,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}
