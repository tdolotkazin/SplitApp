import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("imgLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 220)

            Text("SplitApp")
                .font(.title)
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
