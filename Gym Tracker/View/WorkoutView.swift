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
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                exerciseRow(exercise)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteExercise(exercise)
                        } label: {
                            Label("Delete Exercise", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        
    }
    
    
    
    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        // Note: Relationship cascade will automatically handle associated sets
    }
}

