import Foundation

struct User: Hashable, Decodable {
    let id: UUID
    var name: String
    let phoneNumber: String?
    let email: String?
    let avatarUrl: String?

    init(id: UUID, name: String, phoneNumber: String, email: String? = nil, avatarUrl: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.avatarUrl = avatarUrl
    }

    var avatarURL: URL? {
        Self.resolveAvatarURL(avatarUrl)
    }

    static func resolveAvatarURL(_ value: String?) -> URL? {
        guard let rawValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty
        else {
            return nil
        }

        if rawValue.hasPrefix("//") {
            return URL(string: "https:\(rawValue)")
        }

        if let url = URL(string: rawValue), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }

        let hostCandidate = rawValue.split(separator: "/", maxSplits: 1).first.map(String.init) ?? rawValue
        if hostCandidate.contains(".") {
            return URL(string: "https://\(rawValue)")
        }

        let normalizedPath = rawValue.hasPrefix("/") ? rawValue : "/\(rawValue)"
        let baseURL = URL(string: "https://splitapp.tech")!
        return URL(string: normalizedPath, relativeTo: baseURL)?.absoluteURL
    }
}
