//
//  WorkoutView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    let exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    let allWorkoutOptions: [WorkoutOption]

    var body: some View {
        List(exercises) { exercise in
            ExerciseRowNav(exercise: exercise, allWorkoutOptions: allWorkoutOptions)
        }
        .listStyle(.insetGrouped)
        
    }
    
    

}

