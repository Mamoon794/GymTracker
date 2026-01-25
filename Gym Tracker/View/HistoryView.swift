//
//  HistoryView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2026-01-11.
//

import SwiftUI
import SwiftData
struct ExerciseHistorySheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss
    @State private var showPlateCalc: Bool = false

    var body: some View {
        NavigationStack {
            List {
                // 1. Call your method directly
                let history = exercise.getSourceWorkout().getExercises().sorted(by: { $0.date > $1.date })
                
                if history.isEmpty{
                    ContentUnavailableView("No History", systemImage: "dumbbell")
                } else {
                    ForEach(history) { record in
                        Section(header: Text(record.date.formatted(date: .abbreviated, time: .omitted))
                            .fontWeight(Calendar.current.isDate(record.date, inSameDayAs: exercise.date) ? .bold : .regular)
                        ) {
                            
                            ForEach(sortIndices(sets: record.sets)) { set in
                                HStack {
                                    Text("\(set.reps) reps")
                                        .bold()
                                    Spacer()
                                    Text(displayWeight(set.weight))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History: \(exercise.getName())")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if exercise.getIsBarbellWeight() {
                        Toggle("Plates", isOn: $showPlateCalc)
                            .labelsHidden()
                    }
                }
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


    func displayWeight(_ weight: Double) -> String {
        if showPlateCalc && exercise.getIsBarbellWeight() {
            let plates = (weight - 45) / 2
            return plates >= 0 ? String(format: "%.1f", plates) + " per side" : "0"
        } else {
            return String(format: "%.1f", weight) + " lbs"
        }
    }
}

