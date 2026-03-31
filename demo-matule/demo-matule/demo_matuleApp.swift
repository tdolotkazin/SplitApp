//
//  demo_matuleApp.swift
//  demo-matule
//
//  Created by Valentina Dorina on 31.03.2026.
//

import SwiftUI
import CoreData

@main
struct demo_matuleApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
