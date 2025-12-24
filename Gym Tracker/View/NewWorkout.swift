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
    @State private var selectedCategory: String = workoutCategories[0]
    @State private var customName: String = ""
    
    @Query(sort: \WorkoutOption.name) private var workoutOptions: [WorkoutOption]
    
    var filteredWorkouts: [WorkoutOption] {
        if searchText.isEmpty {
            return workoutOptions
        } else {
            return workoutOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var groupedWorkouts: [String: [WorkoutOption]]{
        Dictionary(grouping: filteredWorkouts, by:{$0.category})
    }
    
    private var categories: [String]{
        groupedWorkouts.keys.sorted()
    }
    
    
    var body: some View{
        NavigationStack{
            List{
                if !searchText.isEmpty && !workoutOptions.contains(where: {$0.name == searchText}){
                    Section("New Entry"){
                        TextField("Workout Name", text: $customName)
                        
                        categoryPicker()
                        
                        Button(action: { addCustomWorkout() }) {
                            Text("Create & Add Exercise")
                        }
                        .disabled(searchText.isEmpty)
                    }
                }
                
                ForEach(categories, id: \.self){category in
                    categoryWorkouts(currCategory: category)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search or type name")
            .onChange(of: searchText) {oldValue, newValue in
                customName = newValue
            }
        }
    }
    
    
    private func categoryWorkouts(currCategory: String) -> some View{
        Section(header: Text(currCategory)){
            ForEach(groupedWorkouts[currCategory] ?? []){ workout in
                Button(action: {selectWorkout (workout)}){
                    HStack {
                        Image(systemName: workout.image)
                            .foregroundColor(.emerald500)
                            .frame(width: 24)
                        Text(workout.name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .onDelete { offsets in
                deleteWorkout(at: offsets, in: groupedWorkouts[currCategory] ?? [])
            }
        }
    }
    
    private func categoryPicker() -> some View{
        Picker("Category", selection: $selectedCategory) {
            ForEach(workoutCategories, id: \.self) { category in
                Text(category).tag(category)
            }
        }
        .pickerStyle(.navigationLink)
    }
    
    
    private func deleteWorkout(at offsets: IndexSet, in categoryList: [WorkoutOption]) {
        for index in offsets {
            // Look up the exercise in the specific list being displayed
            let exerciseToDelete = categoryList[index]
            modelContext.delete(exerciseToDelete)
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
    
    private func addCustomWorkout(){
        print("Name: \(customName), Category: \(selectedCategory)")
        let nameToSave = customName
        let newEntry = WorkoutOption(name: nameToSave, category: selectedCategory, image: "figure.strengthtraining.traditional")
        modelContext.insert(newEntry)
        searchText = ""
        createExercise(from: newEntry.name, image: newEntry.image)
        dismiss()
        
    }
}
