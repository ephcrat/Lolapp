//
//  LolappApp.swift
//  Lolapp
//
//  Created by Alejandro Hernandez on 03/05/2025.
//

import SwiftUI
import SwiftData

let DEFAULT_ACCENT_COLOR: Color = Color.purple

@main
struct LolappApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema: Schema = Schema([
            DailyLog.self,
            FoodEntry.self,
        ])
        let modelConfiguration: ModelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            CalendarView()
                .preferredColorScheme(.light)
                .accentColor(DEFAULT_ACCENT_COLOR)
        }
        .modelContainer(sharedModelContainer)
    }
}
