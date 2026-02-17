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
        let currSourceWorkout = exercise.getSourceWorkout()
        modelContext.delete(exercise)
        try? modelContext.save()
        currSourceWorkout?.updateData()
    }
    
    func updateExercise(_ exercise: Exercise, to option: WorkoutOption){
        let oldSourceWorkout = exercise.getSourceWorkout()
        exercise.sourceWorkout = option
        exercise.name = option.name
        
        exercise.updateData()
        oldSourceWorkout?.updateData()
    }
    
    
    func duplicate(_ exercise: Exercise){
        let sourceWork = exercise.getSourceWorkout()
        let newExercise = Exercise(sourceWorkout: sourceWork, tempName: exercise.getName())
        
        var count = 0
        for currSet in exercise.sets{
            let newSet = ExerciseSet(reps: currSet.reps, weight: currSet.weight, orderIndex: count)
            newExercise.sets.append(newSet)
            count += 1
        }
        
        self.saveExerciseToMonth(exercise: newExercise)
        sourceWork?.lastUpdated = Date.now
        
        modelContext.insert(newExercise)
        try? modelContext.save()
        
        
    }
    
    func createExercise(workoutOption: WorkoutOption){
        let newExercise = Exercise(sourceWorkout: workoutOption)
        self.saveExerciseToMonth(exercise: newExercise)
        modelContext.insert(newExercise)
        try? modelContext.save()
    }


    func saveExerciseToMonth(exercise: Exercise) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: exercise.date)
        let year = calendar.component(.year, from: exercise.date)
        
        
        let descriptor = FetchDescriptor<MonthlyWorkout>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        
        if let existingMonth = try? modelContext.fetch(descriptor).first {
            // 2a. Add to existing month
            existingMonth.exercises.append(exercise)
            exercise.monthly = existingMonth
        } else {
            // 2b. Create new month summary
            let newMonth = MonthlyWorkout(date: exercise.date)
            modelContext.insert(newMonth)
            newMonth.exercises.append(exercise)
            exercise.monthly = newMonth
        }
        
        // 3. Insert the exercise and save
        modelContext.insert(exercise)
        try? modelContext.save()
    }
}

