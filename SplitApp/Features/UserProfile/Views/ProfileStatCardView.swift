import SwiftUI

struct ProfileStatCardView: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.gray)
            Text(value)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(valueColor)
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
