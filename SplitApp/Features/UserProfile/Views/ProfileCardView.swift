import  SwiftUI

struct ProfileCardView: View {
    let initials: String
    let name: String
    let email: String
    
    var body: some View {
        HStack(spacing: 16) {
            avatarCircleWithInitials
            profileText
            Spacer()
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var avatarCircleWithInitials: some View {
        Circle()
            .fill(.green.opacity(0.6))
            .frame(width: 72, height: 72)
            .overlay {
                Text(initials)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
    }
    
    private var profileText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(email)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
