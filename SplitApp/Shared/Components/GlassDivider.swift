import SwiftUI

struct GlassDivider: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.15),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}
