//
//  HistoryView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2026-01-11.
//

import SwiftUI
import SwiftData
struct ExerciseHistorySheet: View {
    let option: WorkoutOption
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                // 1. Call your method directly
                // (Optional: add .sorted if your method doesn't sort by date)
                let history = option.getExercises().sorted(by: { $0.date > $1.date })
                
                if history.isEmpty{
                    ContentUnavailableView("No History", systemImage: "dumbbell")
                } else {
                    ForEach(history) { record in
                        Section(header: Text(record.date.formatted(date: .abbreviated, time: .omitted))) {
                            
                            ForEach(sortIndices(sets: record.sets)) { set in
                                HStack {
                                    Text("\(set.reps) reps")
                                        .bold()
                                    Spacer()
                                    Text("\(set.weight, specifier: "%.1f") \("lbs")")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History: \(option.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    func sortIndices(sets: [ExerciseSet]) -> [ExerciseSet]{
        return sets.sorted {
            $0.orderIndex < $1.orderIndex
        }
    }
}
