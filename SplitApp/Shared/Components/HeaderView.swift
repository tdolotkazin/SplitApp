import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.dividerHighlight)
                    .frame(width: 80, height: 80)
            }

            Text("SplitApp")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Делите счета легко")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HeaderView()
            Spacer()
        }
        .background(Color.white)
    }
}
