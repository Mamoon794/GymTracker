//
//  AllRoutinesView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2026-01-10.
//


import SwiftUI
import SwiftData

struct AllRoutinesView: View {
    var routines: [WorkoutRoutine]
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @State private var showingAddRoutine = false

    // 🎯 Two columns for the grid
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(routines) { routine in
                    RoutineGridItem(routine: routine)
                        .onTapGesture {
                            startRoutine(routine, in: context)
                            dismiss()
                        }
                }
                
                // 2. The "Add New" Button (Last item in grid)
                Button(action: {
                    showingAddRoutine = true
                }) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        Text("Create")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(Color.blue.opacity(0.5))
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingAddRoutine) {
            AddRoutineSheet()
        }
        .navigationTitle("All Routines")
        .background(Color(.systemGroupedBackground))
    }
    
    
    func startRoutine(_ routine: WorkoutRoutine, in context: ModelContext) {
        let sortedItems = routine.items.sorted { $0.orderIndex < $1.orderIndex }
        for item in sortedItems {
            guard let option = item.workoutOption else { continue }
            let newExercise = Exercise(sourceWorkout: option)
            newExercise.date = Date.now
            context.insert(newExercise)
        }
        try? context.save()
    }
}

struct RoutineGridItem: View {
    let routine: WorkoutRoutine
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
            Text("\(routine.items.count) Exercises")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}




struct AddRoutineSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    // Fetch all available exercises from library
    @Query(sort: \WorkoutOption.name) var allOptions: [WorkoutOption]
    
    @State private var routineName: String = ""
    @State private var selectedOptions: [WorkoutOption] = []
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Name
                Section("Routine Details") {
                    TextField("Routine Name (e.g., Leg Day)", text: $routineName)
                }
                
                // Section 2: Exercise Selection
                SelectExercise(allOptions: allOptions, selectedOptions: $selectedOptions)
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                        dismiss()
                    }
                    .disabled(routineName.isEmpty || selectedOptions.isEmpty)
                }
            }
        }
    }
    
    
    // Logic to save data
    func saveRoutine() {
        // 1. Create the Routine container
        let newRoutine = WorkoutRoutine(name: routineName, colorHex: "#3366FF")
        context.insert(newRoutine)
        
        // 2. Create items for selected exercises
        // Note: Using a set loses order, so we just sort alphabetically or by library order for now
        
        for (index, option) in selectedOptions.enumerated() {
            let item = RoutineItem(orderIndex: index, workoutOption: option)
            item.routine = newRoutine // Link to parent
            context.insert(item)
        }
        
        // 3. Save
        try? context.save()
    }
}


struct SelectExercise: View{
    var allOptions: [WorkoutOption]
    @Binding var selectedOptions: [WorkoutOption]
    var body: some View{
        Section("Select Exercises") {
            ForEach(allOptions) { option in
                HStack {
                    // Image/Icon
                    exerciseIcon(imageData: option.getImageData(), iconName: option.getImage())
                        .foregroundStyle(.blue)
                        .frame(width: 24, height: 24)
                    
                    Text(option.name)
                    
                    Spacer()
                    
                    // Checkmark logic
                    if selectedOptions.firstIndex(of: option) != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle()) // Makes whole row tappable
                .onTapGesture {
                    toggleSelection(for: option)
                }
            }
        }
    }

    // Helper to toggle selection
    func toggleSelection(for option: WorkoutOption) {
        if let index = selectedOptions.firstIndex(of: option) {
            selectedOptions.remove(at: index)
        } else {
            selectedOptions.append(option)
        }
    }
}

