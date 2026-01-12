//
//  WorkoutSelectionView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2026-01-11.
//

import SwiftUI
import SwiftData

struct WorkoutChangeView: View {
    @Bindable var exercise: Exercise
    var ops: DBOperations
    @Environment(\.dismiss) private var dismiss
    

    @Query(sort: \WorkoutOption.name) private var allOptions: [WorkoutOption]
    @State private var searchText = ""
    
    var filteredOptions: [WorkoutOption] {
        if searchText.isEmpty { return allOptions }
        return allOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(filteredOptions) { option in
            Button {
                ops.updateExercise(exercise, to: option)
                
                
                dismiss()
            } label: {
                HStack {
                    
                    if exercise.sourceWorkout == option {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    Text(option.name)
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select Exercise")
        .searchable(text: $searchText, placement: .navigationBarDrawer) 
    }
}



struct WorkoutSelectionView: View {
    @Binding var selectedOption: String
    @Environment(\.dismiss) private var dismiss
    

    @Query(sort: \WorkoutOption.name) private var allOptions: [WorkoutOption]
    @State private var searchText = ""
    
    var filteredOptions: [WorkoutOption] {
        if searchText.isEmpty { return allOptions }
        return allOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(filteredOptions) { option in
            Button {
                selectedOption = option.name
                dismiss()
            } label: {
                HStack {
                    if selectedOption == option.name {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    Text(option.name)
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Select Exercise")
        .searchable(text: $searchText, placement: .navigationBarDrawer)
    }
}
