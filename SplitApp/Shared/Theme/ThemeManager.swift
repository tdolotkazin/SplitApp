
import SwiftUI
import Combine

enum ThemeMode: String, CaseIterable {
    case light = "Светлая"
    case dark = "Тёмная"
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: ThemeMode = .light {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    static let shared = ThemeManager()

    private init() {
        // Загрузить сохранённую тему
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = ThemeMode(rawValue: savedTheme) {
            currentTheme = theme
        }
    }

    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
}
