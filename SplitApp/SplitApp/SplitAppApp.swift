//
//  SplitAppApp.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import SwiftUI
import CoreData

@main
struct SplitAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
