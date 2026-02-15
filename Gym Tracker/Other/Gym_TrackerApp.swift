//
//  Gym_TrackerApp.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData
import ActivityKit

@main
struct Gym_TrackerApp: App {
    @State private var timerManager = RestTimerManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutOption.self,
            Exercise.self,
            WorkoutStat.self,
            WorkoutRoutine.self,
            RoutineItem.self,
            MonthlyWorkout.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
            .environment(timerManager)
            .alert("Rest Complete", isPresented: $timerManager.showTimerAlert) {
                Button("OK", role: .cancel) {
                    // Determine what happens when they click OK (usually nothing)
                }
                Button("+30s") {
                    timerManager.addTime(30)
                }
            } message: {
                Text("Get ready for your next set!")
            }
            .onAppear {
                    DataMigrator.fixMissingMonths(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
        

    }
}
