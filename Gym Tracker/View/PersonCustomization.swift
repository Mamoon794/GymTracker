//
//  PersonCustomization.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-30.
//


import SwiftUI
import SwiftData


struct PersonCustomization: View {
    // 1. Fetch your options from the database
    @Query private var allWorkoutOptions: [WorkoutOption]
    @Environment(\.modelContext) private var modelContext
    @State private var draftNames: [PersistentIdentifier: String] = [:]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allWorkoutOptions) { option in
                    Section(header: Text(option.name)) {
                        
                        HStack(spacing: 12) {
                            // 1. Your new separate image component
                            ExerciseImageThumbnail(option: option)
                            
                            // 2. Your existing validated TextField
                            VStack(alignment: .leading) {
                                TextField("Exercise Name", text: Binding(
                                    get: { draftNames[option.id] ?? option.name },
                                    set: { newValue in
                                        if isNameValid(newValue, for: option){
                                            option.name = newValue
                                        }
                                        draftNames[option.id] = newValue
                                    }
                                ))
                                .foregroundColor(isNameValid(draftNames[option.id] ?? option.name, for: option) ? .primary : .red)
                            }
                        }
                        
                        
                        // Edit Category using our Enum
                        Picker("Category", selection: Binding(
                            get: { option.category },
                            set: { option.category = $0 }
                        )) {
                            ForEach(WorkoutCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        
                        // Edit Barbell Toggle
                        Toggle(isOn: Binding(
                            get: { option.isBarbellWeight },
                            set: { option.isBarbellWeight = $0 }
                        )) {
                            Label("Is Barbell Weight", systemImage: "dumbbell.fill")
                                
                        }
                    }
                }
            }
            .navigationTitle("Workout Library")
        }
    }
    
    private func deleteOptions(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(allWorkoutOptions[index])
        }
    }
    
    private func isNameValid(_ name: String, for option: WorkoutOption) -> Bool {
        let cleaned = name.trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return false }
        
        // Check if the name exists elsewhere
        let isDuplicate = allWorkoutOptions.contains {
            $0.name.lowercased() == cleaned.lowercased() && $0.id != option.id
        }
        
        return !isDuplicate
    }
}

