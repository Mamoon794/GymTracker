//
//  exercise.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-22.
//

import SwiftData
import Foundation


@Model
class Exercise{
    var id: UUID = UUID()
    var name: String
    var date: Date = Date.now
    
    
    @Relationship(deleteRule: .nullify)
    var sourceWorkout: WorkoutOption?
    
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet] = []
    
    var totalSets: Int{
        sets.count
    }
    
    init(sourceWorkout: WorkoutOption?, theDate: Date = Date.now){
        var workout = sourceWorkout
        self.date = theDate
        if (sourceWorkout == nil){
            workout = WorkoutOption(name: "Chest", category: WorkoutCategory.chest)
        }
        self.name = workout?.name ?? "Chest"
        self.sourceWorkout = sourceWorkout
    }
    
    func getIsBarbellWeight() -> Bool {
        return sourceWorkout?.isBarbellWeight ?? false
    }
    
    func getImageName() -> String{
        return sourceWorkout?.getImage() ?? "figure.strengthtraining.traditional"
    }
    
    func getName() -> String{
        return sourceWorkout?.name ?? self.name
    }
    
    func getImageData() -> Data?{
        return self.sourceWorkout?.imageData
    }

    func getTimerSeconds() -> Double {
        return self.sourceWorkout?.timerSeconds ?? 90
    }
    
    func getCategory() -> WorkoutCategory{
        return self.sourceWorkout?.category ?? WorkoutCategory.chest
    }
    
    func getSourceWorkout() -> WorkoutOption{
        return self.sourceWorkout ?? WorkoutOption(name: self.name, category: WorkoutCategory.chest)
    }
    
    func synchronizeIndices() {
        let sorted = sets.sorted { $0.orderIndex < $1.orderIndex }
        for (index, set) in sorted.enumerated() {
            set.orderIndex = index
        }
    }
}

@Model
class ExerciseSet {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var exercise: Exercise? // Backlink to the parent exercise
    var orderIndex: Int

    init(reps: Int, weight: Double, orderIndex: Int) {
        self.reps = reps
        self.weight = weight
        self.orderIndex = orderIndex
    }
}

enum WorkoutCategory: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case cardio = "Cardio"
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .legs: return "figure.run"
        case .shoulders: return "figure.arms.open"
        case .arms: return "hand.raised.fill"
        case .core: return "figure.core.training"
        case .cardio: return "heart.fill"
        }
    }
    
    var id: String { self.rawValue }
}


@Model
class WorkoutOption {
    var id: UUID = UUID()
    var name: String
    var category: WorkoutCategory
    @Transient var image: String = WorkoutCategory.chest.icon
    var imageData: Data?
    var isBarbellWeight: Bool = false
    var lastUpdated: Date = Date()
    var timerSeconds: Double = 90
    
    @Relationship(deleteRule: .nullify, inverse: \Exercise.sourceWorkout)
        var exercises: [Exercise]?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutStat.sourceWorkout)
        var stats: WorkoutStat?
    
    init(name: String, category: WorkoutCategory, isBarbellWeight: Bool = false) {
        self.name = name
        self.category = category
        self.isBarbellWeight = isBarbellWeight
    }
    
    func getExercises() -> [Exercise] {
        let allExercises = self.exercises ?? []
        return allExercises.filter { $0.totalSets > 0 }
    }

    func getImage() -> String {
        return self.category.icon
    }

    func getImageData() -> Data? {
        return self.imageData
    }
    
}

struct maxEntries: Codable {
    var date: Date
    var max: Double
}

@Model
class WorkoutStat {
    var workoutName: String
    var oneRepMaxHistory: [maxEntries]
    var maxWeightHistory: [maxEntries]
    var frequency: Int
    var totalVolume: Double
    var totalExercises: Int
    var totalDays: Int
    var lastUpdated: Date

    var sourceWorkout: WorkoutOption

    init(workout: WorkoutOption) {
        self.sourceWorkout = workout
        self.workoutName = workout.name
        self.workoutName = workout.name
        self.lastUpdated = Date()
        self.oneRepMaxHistory = []
        self.maxWeightHistory = []
        self.frequency = 0
        self.totalVolume = 0.0
        self.totalExercises = 0
        self.totalDays = 0
        self.recalculateStats()
        
    }
    
    func recalculateStats() {
        let exercises = sourceWorkout.getExercises()
        // 1. Calculate 1RM History
        let history = exercises.compactMap { exercise -> maxEntries? in
            
            let dailyMax = exercise.sets.map { set in
                // Brzycki Formula
                return set.weight * (1.0 + Double(set.reps) / 30.0)
            }.max()
            
            
            if let max = dailyMax {
                return maxEntries(date: exercise.date, max: max)
            }
            return nil
        }
        
        
        self.oneRepMaxHistory = history.sorted { $0.date < $1.date }
        
        
        self.frequency = exercises.count
        self.totalVolume = exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
        
        self.totalExercises = exercises.count
        self.lastUpdated = Date.now
    }
    
    func updateData(){
        if (sourceWorkout.lastUpdated > self.lastUpdated){
            self.recalculateStats()
        }
    }
    
}


@Model
class WorkoutRoutine{
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var clickFrequency: Int
    

    @Relationship(deleteRule: .cascade)
    var items: [RoutineItem] = []
    
    init(name: String, colorHex: String = "#10B981") {
        self.name = name
        self.colorHex = colorHex
        self.clickFrequency = 0
    }
}



@Model
class RoutineItem {
    var id: UUID = UUID()
    var orderIndex: Int
    
    var workoutOption: WorkoutOption?
    
    @Relationship(inverse: \WorkoutRoutine.items)
    var routine: WorkoutRoutine?
    
    init(orderIndex: Int, workoutOption: WorkoutOption) {
        self.orderIndex = orderIndex
        self.workoutOption = workoutOption
    }
}

