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

    var body: some View {
        List(exercises) { exercise in
            ExerciseRowNav(exercise: exercise)
        }
        .listStyle(.insetGrouped)
        
    }
    
    

}

