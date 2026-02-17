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

    var oneRepMax: Double {
        let bestSet = sets.max { a, b in
            let valA = a.weight * (1.0 + Double(a.reps) / 30.0)
            let valB = b.weight * (1.0 + Double(b.reps) / 30.0)
            return valA < valB
        }
        
        guard let best = bestSet else { return 0.0 }
        return best.weight * (1.0 + Double(best.reps) / 30.0)
    }

    var maxWeight: Double {
        return sets.max { $0.weight < $1.weight }?.weight ?? 0.0
    }
    
    
    @Relationship(deleteRule: .nullify)
    var sourceWorkout: WorkoutOption?
    
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet] = []

    var monthly: MonthlyWorkout?
    
    var totalSets: Int{
        sets.count
    }
    
    init(sourceWorkout: WorkoutOption?, theDate: Date = Date.now, tempName: String = ""){
        let workout = sourceWorkout
        self.date = theDate
        self.name = workout?.name ?? tempName
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
    
    func getSourceWorkout() -> WorkoutOption?{
        return self.sourceWorkout
    }

    func getWorkoutStat() -> WorkoutStat? {
        return self.getSourceWorkout()?.stats
    }
    
    func synchronizeIndices() {
        let sorted = sets.sorted { $0.orderIndex < $1.orderIndex }
        for (index, set) in sorted.enumerated() {
            set.orderIndex = index
        }
    }
    
    func updateData(){
        self.getSourceWorkout()?.updateData()
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
    var showTimer: Bool = true
    
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
    
    func updateData(){
        self.lastUpdated = Date.now
        self.stats?.recalculateStats()
    }
    
}

struct maxEntries: Codable {
    var date: Date
    var max: Double
}

struct maxWeightEntry: Codable {
    var date: Date
    var id: UUID
    var weightValue: Double
}

struct maxOneRepEntry: Codable {
    var date: Date
    var id: UUID
    var oneRepMaxValue: Double
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
    var maxWeightStat: maxWeightEntry?
    var maxOneRepStat: maxOneRepEntry?

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
        self.oneRepMaxHistory = []
        self.frequency = 0
        self.totalVolume = 0
        self.totalExercises = 0
        self.maxWeightStat = nil
        self.maxOneRepStat = nil


        let exercises = sourceWorkout.getExercises().sorted{ $0.date < $1.date }

        var history: [maxEntries] = []
        var weightHistory: [maxEntries] = []

        for exercise in exercises {
            let current1RM = exercise.oneRepMax
            let currentMaxWeight = exercise.maxWeight
            if current1RM > 0 {
                history.append(maxEntries(date: exercise.date, max: current1RM))
                
                if current1RM > self.maxOneRepStat?.oneRepMaxValue ?? 0 {
                    self.maxOneRepStat = maxOneRepEntry(date: exercise.date, id: exercise.id, oneRepMaxValue: current1RM)
                }
            }
            if currentMaxWeight > 0{
                weightHistory.append(maxEntries(date: exercise.date, max: currentMaxWeight))
                
                if currentMaxWeight > self.maxWeightStat?.weightValue ?? 0 {
                    self.maxWeightStat = maxWeightEntry(date: exercise.date, id: exercise.id, weightValue: currentMaxWeight)
                }
            }
        }
        
        
        self.oneRepMaxHistory = history
        self.maxWeightHistory = weightHistory
        
        
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


@Model
class MonthlyWorkout{
    var id: UUID = UUID()
    var month: Int
    var year: Int
    

    @Relationship(deleteRule: .nullify, inverse: \Exercise.monthly)
    var exercises: [Exercise] = []
    
    init(date: Date) {
        let calendar = Calendar.current
        self.month = calendar.component(.month, from: date)
        self.year = calendar.component(.year, from: date)
    }
    
    // Helper to get a readable name like "January 2025"
    var displayName: String {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents) {
            return date.formatted(.dateTime.month(.wide).year())
        }
        return "\(month)/\(year)"
    }
    
    // Helper for sorting or finding unique months
    var idString: String {
        return "\(year)-\(month)"
    }
    
    // Dynamic Stats for this specific month
    var totalExercises: Int {
        exercises.count
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    var totalDays: Int {
        let uniqueDays = Set(exercises.map { Calendar.current.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    func getExercises(date: Date) -> [Exercise] {
        return exercises.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

}
