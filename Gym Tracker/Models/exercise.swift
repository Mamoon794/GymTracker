//
//  exercise.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-22.
//

import SwiftData
import Foundation

let workoutCategories = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Core", "Cardio"]

@Model
class Exercise{
    var id: UUID = UUID()
    var name: String
    var imageName: String
    var date: Date = Date.now
    
    @Relationship(deleteRule: .cascade)
    var sets: [ExerciseSet] = []
    
    var totalSets: Int{
        sets.count
    }
    
    init(name: String, imageName: String){
        self.name = name
        self.imageName = imageName
    }
}

@Model
class ExerciseSet {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var exercise: Exercise? // Backlink to the parent exercise

    init(reps: Int, weight: Double) {
        self.reps = reps
        self.weight = weight
    }
}


@Model
class WorkoutOption {
    var id: UUID = UUID()
    var name: String
    var category: String
    var image: String
    
    init(name: String, category: String, image: String) {
        self.name = name
        self.image = image
        self.category = category
    }
}

