import SwiftUI

struct ProfileStatCardView: View {
    let profileData: ProfileScreenModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            itemTitle
            itemValue
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var itemTitle: some View {
        Text(item.title)
            .font(.subheadline)
            .foregroundStyle(.black)
    }

    private var itemValue: some View {
        Text(item.value)
            .font(.system(size: 28, weight: .medium))
    }
}

