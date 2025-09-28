//
//  PulsumApp.swift
//  Pulsum
//
//  Created by Martin Demel on 9/28/25.
//

import SwiftUI
import CoreData

@main
struct PulsumApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
