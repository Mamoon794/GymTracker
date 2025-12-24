//
//  Gym_TrackerApp.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData

@main
struct Gym_TrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Exercise.self, ExerciseSet.self, WorkoutOption.self])
    }
}
