//
//  NewWokout.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-23.
//

import SwiftUI
import SwiftData


struct NewWorkout: View{
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    @Query(sort: \WorkoutOption.name) private var workoutOptions: [WorkoutOption]
    
    var filteredWorkouts: [WorkoutOption] {
        if searchText.isEmpty {
            return workoutOptions
        } else {
            return workoutOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    
    var body: some View{
        NavigationStack{
            List{
                if !searchText.isEmpty && !workoutOptions.contains(where: {$0.name == searchText}){
                    Section("New Entry"){
                        Button(action: { addCustomWorkout(name: searchText) }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Create \"\(searchText)\"")
                            }
                        }
                    }
                }
                
                Section("New Workout"){
                    ForEach(filteredWorkouts){ workout in
                        Button(action: {selectWorkout (workout)}){
                            Text(workout.name).foregroundColor(.primary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or type name")
        }
    }
    
    private func selectWorkout(_ workout: WorkoutOption){
        createExercise(from: workout.name, image: workout.image)
        dismiss()
    }
    
    private func createExercise(from name: String, image: String){
        let newExercise = Exercise(name: name, imageName: image)
        modelContext.insert(newExercise)
    }
    
    private func addCustomWorkout(name: String){
        let newEntry = WorkoutOption(name: name, image: "figure.strengthtraining.traditional")
        modelContext.insert(newEntry)
        searchText = ""
        print("Created and selected custom workout: \(name)")
    }
}
