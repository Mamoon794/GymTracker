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
    
    init(sourceWorkout: WorkoutOption?){
        var workout = sourceWorkout
        if (sourceWorkout == nil){
            workout = WorkoutOption(name: "Chest", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)
        }
        self.name = workout?.name ?? "Chest"
        self.sourceWorkout = sourceWorkout
    }
    
    func getIsBarbellWeight() -> Bool {
        return sourceWorkout?.isBarbellWeight ?? false
    }
    
    func getImageName() -> String{
        return sourceWorkout?.image ?? "figure.strengthtraining.traditional"
    }
    
    func getName() -> String{
        return sourceWorkout?.name ?? self.name
    }
    
    func getImageData() -> Data?{
        return self.sourceWorkout?.imageData
    }
    
    func getCategory() -> WorkoutCategory{
        return self.sourceWorkout?.category ?? WorkoutCategory.chest
    }
    
    func getSourceWorkout() -> WorkoutOption{
        return self.sourceWorkout ?? WorkoutOption(name: self.name, category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)
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
    var image: String
    var imageData: Data?
    var isBarbellWeight: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \Exercise.sourceWorkout)
        var exercises: [Exercise]?
    
    init(name: String, category: WorkoutCategory, image: String, isBarbellWeight: Bool = false) {
        self.name = name
        self.image = image
        self.category = category
        self.isBarbellWeight = isBarbellWeight
    }
}




