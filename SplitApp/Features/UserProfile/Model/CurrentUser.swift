import Combine
import SwiftUI

struct CurrentUser {
    let id: UUID
    let name: String
    let initials: String
    let avatarURL: URL?
    let color: Color
    let email: String?
    let phoneNumber: String?
}

@MainActor
final class CurrentUserStore: ObservableObject {
    static let shared = CurrentUserStore()

    @Published var user: CurrentUser?

    private init() {}

    func updateFromAuth(_ authUser: User) {
        let initials = makeInitials(from: authUser.name)
        let avatarURL = authUser.avatarURL

        user = CurrentUser(
            id: authUser.id,
            name: authUser.name,
            initials: initials,
            avatarURL: avatarURL,
            color: Color(hex: "#7CB342"),
            email: authUser.email,
            phoneNumber: authUser.phoneNumber
        )

        print("✅ CurrentUserStore: Updated user - \(authUser.name) (ID: \(authUser.id))")
        if let avatarURL {
            print("🖼️ CurrentUserStore: Avatar URL - \(avatarURL.absoluteString)")
        } else {
            print("⚠️ CurrentUserStore: No avatar URL (avatarUrl from API: \(authUser.avatarUrl ?? "nil"))")
        }

        // Сохраняем в UserDefaults для быстрого доступа
        saveToUserDefaults()
    }

    func loadFromUserDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let decoded = try? JSONDecoder().decode(CurrentUserData.self, from: data)
        else {
            print("⚠️ CurrentUserStore: No saved user in UserDefaults")
            return
        }

        user = CurrentUser(
            id: decoded.id,
            name: decoded.name,
            initials: decoded.initials,
            avatarURL: User.resolveAvatarURL(decoded.avatarURLString),
            color: Color(hex: "#7CB342"),
            email: decoded.email,
            phoneNumber: decoded.phoneNumber
        )
        print("✅ CurrentUserStore: Loaded user from UserDefaults - \(decoded.name)")
    }

    func clear() {
        user = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    private func saveToUserDefaults() {
        guard let user else { return }
        let data = CurrentUserData(
            id: user.id,
            name: user.name,
            initials: user.initials,
            avatarURLString: user.avatarURL?.absoluteString,
            email: user.email,
            phoneNumber: user.phoneNumber
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    private func makeInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let second = components[1].prefix(1).uppercased()
            return first + second
        } else if let first = components.first {
            return String(first.prefix(2).uppercased())
        }
        return "?"
    }
}

private struct CurrentUserData: Codable {
    let id: UUID
    let name: String
    let initials: String
    let avatarURLString: String?
    let email: String?
    let phoneNumber: String?
}

extension CurrentUser {
    func toParticipant() -> Participant {
        Participant(
            id: id,
            name: name,
            initials: initials,
            color: color,
            avatarURL: avatarURL
        )
    }
}

extension CurrentUserStore {
    func toParticipant() -> Participant? {
        user?.toParticipant()
    }
}
