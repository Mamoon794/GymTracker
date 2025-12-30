//
//  dbOperations.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-29.
//


import SwiftData
import SwiftUI


final class DBOperations {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
    }
    
    func rename(_ exercise: Exercise, to name: String){
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            withAnimation {
                exercise.name = trimmedName
            
            }
        }
    }
    
    
    func duplicate(_ exercise: Exercise){
        let newExercise = Exercise(name: exercise.name, imageName: exercise.imageName)
        
        for currSet in exercise.sets{
            let newSet = ExerciseSet(reps: currSet.reps, weight: currSet.weight)
            newExercise.sets.append(newSet)
        }
        
        modelContext.insert(newExercise)
        
        
    }
}

