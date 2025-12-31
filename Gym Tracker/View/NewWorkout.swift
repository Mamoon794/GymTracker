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
    @State private var selectedCategory: WorkoutCategory = .chest
    @State private var customName: String = ""
    private var ops: DBOperations { DBOperations(modelContext: modelContext) }
    @State private var isBarbell: Bool = false
    
    @Query(sort: \WorkoutOption.name) private var workoutOptions: [WorkoutOption]
    
    var filteredWorkouts: [WorkoutOption] {
        if searchText.isEmpty {
            return workoutOptions
        } else {
            return workoutOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var groupedWorkouts: [WorkoutCategory: [WorkoutOption]]{
        Dictionary(grouping: filteredWorkouts, by:{$0.category})
    }
    
    private var categories: [WorkoutCategory]{
        groupedWorkouts.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    
    var body: some View{
        NavigationStack{
            List{
                if !searchText.isEmpty && !workoutOptions.contains(where: {$0.name == searchText}){
                    Section {
                        VStack(alignment: .leading, spacing: 15) {
                            // 1. Text Input with clear label
                            VStack(alignment: .leading, spacing: 5) {
                                Text("WORKOUT NAME")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                TextField("e.g. Incline Bench Press", text: $customName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                            }
                            
                            Divider()
                            
                            // 2. Options Row
                            
                            categoryPicker() // Ensure this is styled as a Menu or compact picker
                            
                            Toggle(isOn: $isBarbell) {
                                Label("Barbell", systemImage: "dumbbell.fill")
                            }
                            .toggleStyle(.button)
                            .tint(isBarbell ? .emerald500 : .accentColor)
                            .controlSize(.small)
                            
                            
                            // 3. Primary Action Button
                            Button(action: { addCustomWorkout() }) {
                                Text("Create & Add Exercise")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.emerald500)
                            .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.vertical, 5)
                    } header: {
                        Text("New Entry")
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
    
    
    private func categoryWorkouts(currCategory: WorkoutCategory) -> some View{
        Section(header: Text(currCategory.rawValue)){
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
            ForEach(WorkoutCategory.allCases) { category in
                Text(category.rawValue).tag(category)
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
        // If your DB layer supports storing whether the set uses a barbell, pass `isBarbellWeight` here.
        ops.createExercise(workoutOption: workout)
        dismiss()
    }

    
    private func addCustomWorkout(){
        print("Name: \(customName), Category: \(selectedCategory)")
        let nameToSave = customName
        let newWorkout = WorkoutOption(name: nameToSave, category: selectedCategory, image: "figure.strengthtraining.traditional", isBarbellWeight: isBarbell)
        // Note: `isBarbellWeight` indicates whether this exercise uses a barbell. Wire this into your model as needed.
        modelContext.insert(newWorkout)
        searchText = ""
        // If your DB layer supports storing whether the set uses a barbell, pass `isBarbellWeight` here.
        ops.createExercise(workoutOption: newWorkout)
        dismiss()
        
    }
}

