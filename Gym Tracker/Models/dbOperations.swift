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
    
    func updateExercise(_ exercise: Exercise, to option: WorkoutOption?){
        exercise.sourceWorkout = option
        exercise.name = option?.name ?? exercise.name
    }
    
    
    func duplicate(_ exercise: Exercise){
        let sourceWork = exercise.sourceWorkout ?? WorkoutOption(name: exercise.name, category: WorkoutCategory.chest, image: "figure.strengthtraining.traditional")
        let newExercise = Exercise(sourceWorkout: sourceWork)
        
        for currSet in exercise.sets{
            let newSet = ExerciseSet(reps: currSet.reps, weight: currSet.weight, orderIndex: exercise.totalSets)
            newExercise.sets.append(newSet)
        }
        
        modelContext.insert(newExercise)
        
        
    }
    
    func createExercise(workoutOption: WorkoutOption){
        let newExercise = Exercise(sourceWorkout: workoutOption)
        modelContext.insert(newExercise)
    }
}

