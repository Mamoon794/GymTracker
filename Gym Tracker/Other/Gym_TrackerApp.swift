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
        }
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutOption.self, WorkoutStat.self, WorkoutRoutine.self, RoutineItem.self])
        

    }
}
