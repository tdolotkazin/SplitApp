import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image("imgLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 360, maxHeight: 300)

            Text("SplitApp")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Text("Делите счета легко")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.38))
        }
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
