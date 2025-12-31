//
//  publicFuncs.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-29.
//

import SwiftUI
import SwiftData
import ImagePlayground


extension Color {
      static let emerald400 = Color(red: 0.06, green: 0.78, blue: 0.53) // example values
      static let emerald500 = Color(red: 0.00, green: 0.70, blue: 0.50)
      static let slate400   = Color(red: 0.56, green: 0.60, blue: 0.67)
      static let slate800   = Color(red: 0.12, green: 0.14, blue: 0.18)
      static let slate300   = Color(red: 0.69, green: 0.73, blue: 0.78)
}

extension ShapeStyle where Self == Color {
    static var emerald400: Color{ Color(red: 0.06, green: 0.78, blue: 0.53) }
    static var emerald500: Color { Color(red: 0.00, green: 0.70, blue: 0.50) }
    static var slate400: Color { Color(red: 0.56, green: 0.60, blue: 0.67) }
    static var slate800: Color { Color(red: 0.12, green: 0.14, blue: 0.18) }
    static var slate300: Color{ Color(red: 0.69, green: 0.73, blue: 0.78)}
    
}


func triggerSuccessHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare() // Reduces latency
    generator.impactOccurred()
}

struct ExerciseRowNav: View{
    let exercise: Exercise
    let allWorkoutOptions: [WorkoutOption]
    @Environment(\.modelContext) private var modelContext
    private var ops: DBOperations { DBOperations(modelContext: modelContext) }
    @State private var showingRenameAlert = false
    @State private var selectedOption: WorkoutOption?
    
    var groupedByCategory: [(category: WorkoutCategory, options: [WorkoutOption])] {
        let grouped = Dictionary(grouping: allWorkoutOptions) { $0.category }
        return grouped
            .map { (key, value) in (category: key, options: value) }
            .sorted { $0.category.rawValue < $1.category.rawValue }
    }
    
    var body: some View{
        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
            exerciseRow(exercise)
            .contextMenu {
                Button(role: .destructive) {
                    ops.deleteExercise(exercise)
                } label: {
                    Label("Delete Exercise", systemImage: "trash")
                }
                Button {
                    ops.duplicate(exercise)
                    triggerSuccessHaptic()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Menu {
                    ForEach(allWorkoutOptions) { option in
                        Button {
                            ops.updateExercise(exercise, to: option)
                        } label: {
                            // 2. Simplified label logic
                            if exercise.sourceWorkout?.id == option.id {
                                Label(option.name, systemImage: "checkmark")
                            } else {
                                Text(option.name)
                            }
                        }
                    }
                    
                    
                } label: {
                    Label("Change Exercise Type", systemImage: "pencil")
                }
                
            }
        }
        
    }
    
    func exerciseRow(_ exercise: Exercise) -> some View{
        HStack(spacing: 12) {
            exerciseIcon(for: exercise.sourceWorkout)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.getName())
                    .font(.headline)
                Text("Sets: \(exercise.totalSets)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func exerciseIcon(for option: WorkoutOption?) -> some View {
        if let data = option?.imageData, let uiImage = UIImage(data: data) {
            // 🎯 Show the Generated Image
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill() // Fill the frame for a better look
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            // 🎯 Fallback to the System Icon
            Image(systemName: option?.category.icon ?? "dumbbell.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundStyle(.tint)
        }
    }
}







struct ImageGenerator {
    
    static func getConcepts(for name: String) -> [ImagePlaygroundConcept] {
        let strings = [name, "fitness icon", "minimalist", "gym equipment"]
        
        return strings.map { .text($0) }
    }
    
    
    static func processResult(from url: URL, for option: WorkoutOption) {
        do {
            let data = try Data(contentsOf: url)
            option.imageData = data
        } catch {
            print("Failed to process Image Playground result: \(error)")
        }
    }
}


struct ExerciseImageThumbnail: View {
    @Bindable var option: WorkoutOption
    @State private var isShowingPlayground = false
    
    var body: some View {
        Button {
            isShowingPlayground = true
        } label: {
            Group {
                if let data = option.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 20))
                        .foregroundStyle(.emerald500)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.slate800.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        // 🎯 Calling the separate logic here
        .imagePlaygroundSheet(
            isPresented: $isShowingPlayground,
            concepts: ImageGenerator.getConcepts(for: option.name)
        ) { url in
            ImageGenerator.processResult(from: url, for: option)
        }
    }
}
