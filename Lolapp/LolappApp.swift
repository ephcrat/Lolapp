//
//  LolappApp.swift
//  Lolapp
//
//  Created by Alejandro Hernandez on 03/05/2025.
//

import SwiftUI
import SwiftData

@main
struct LolappApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            CalendarView()
        }
        .modelContainer(sharedModelContainer)
    }
}
