//
//  WorkoutView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRoutine.clickFrequency, order: .reverse) var routines: [WorkoutRoutine]
    
    @Query(filter: #Predicate<Exercise> { exercise in
            exercise.date >= todayStart && exercise.date < tomorrowStart
        }, sort: \Exercise.date) private var exercises: [Exercise]
        
    

    var body: some View {
        // 1. Remove spacing between Picker and List
        VStack(spacing: 0) {
            
            RoutinePickerView(routines: routines)
            
            
            List(exercises) { exercise in
                ExerciseRowNav(exercise: exercise)
            }
            .listStyle(.insetGrouped)
        }
    }
    
}


struct RoutinePickerView: View {
    var routines: [WorkoutRoutine]
    @Environment(\.modelContext) var context
    @State private var isExpanded: Bool = false
        
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Routines")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
            }

            // 3. The Collapsible Content
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack(spacing: 12) {
                        NavigationLink(destination: AllRoutinesView(routines: routines)) {
                            VStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title)
                                    
                                Text("All")
                                    .font(.caption)
                                    
                            }
                            .frame(width: 80, height: 80)
                            
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        ForEach(routines.prefix(5)) { routine in
                            RoutineButton(routine: routine)
                        }
                        
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 0) // Adjusted spacing
                    .padding(.bottom, 12)
                }
            
                
            }
            
        }
        .background(Color(.systemGroupedBackground))
    }
    
    func RoutineButton(routine: WorkoutRoutine) -> some View {
        Button(action: {
            startRoutine(routine, in: context)
        }) {
            VStack(alignment: .leading) {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(routine.items.count) Exercises")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(Color.blue) // Fallback color used here
            .clipShape(RoundedRectangle(cornerRadius: 12))
        
        }
    }
    
    func startRoutine(_ routine: WorkoutRoutine, in context: ModelContext) {
        
        let sortedItems = routine.items.sorted { $0.orderIndex < $1.orderIndex }
        
        
        for item in sortedItems {
            guard let option = item.workoutOption else { continue }
            
            
            let newExercise = Exercise(sourceWorkout: option)
            
            
            
            context.insert(newExercise)
        }
        
        routine.clickFrequency += 1
        
        
        try? context.save()
    }
}
//
//#Preview{
//    let workout = WorkoutOption(name: "Bench Press", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)
//    WorkoutView(exercises: [Exercise(sourceWorkout: workout)], allWorkoutOptions: [workout])
//}

