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
    
    private func exerciseRow(_ exercise: Exercise) -> some View{
        HStack(spacing: 12) {
            Image(systemName: exercise.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                Text("Sets: \(exercise.totalSets)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        // Note: Relationship cascade will automatically handle associated sets
    }
}

