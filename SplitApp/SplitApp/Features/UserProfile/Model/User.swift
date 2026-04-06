import Foundation

struct User {
    let id: String
    let token: String
    let provider: AuthProvider
}

enum AuthProvider {
    case yandex
   // case google
    case apple
}
