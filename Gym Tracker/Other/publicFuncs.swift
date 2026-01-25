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

var todayStart: Date {
        Calendar.current.startOfDay(for: .now)
    }
    
var tomorrowStart: Date {
    Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
}


func triggerSuccessHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare() // Reduces latency
    generator.impactOccurred()
}

struct ExerciseRowNav: View{
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    private var ops: DBOperations { DBOperations(modelContext: modelContext) }
    @State private var showingRenameAlert = false
    @State private var selectedOption: WorkoutOption?
    @State private var showSelectionSheet = false
    
    
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
                Button {
                    showSelectionSheet = true
                } label: {
                    Label("Change Exercise Type", systemImage: "pencil")
                }
                
            }
            .sheet(isPresented: $showSelectionSheet) {
                NavigationStack {
                    WorkoutChangeView(exercise: exercise, ops: ops)
                }
                .presentationDetents([.medium, .large])
            }
        }
        
    }
    
    func exerciseRow(_ exercise: Exercise) -> some View{
        HStack(spacing: 12) {
            exerciseIcon(imageData: exercise.getImageData(), iconName: exercise.getCategory().icon)
            .frame(width: 32, height: 32)

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
    
}



@ViewBuilder
func exerciseIcon(imageData: Data?, iconName: String) -> some View {
    if let data = imageData, let uiImage = UIImage(data: data) {
        // 🎯 Show the Generated Image
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill() // Fill the frame for a better look
            .clipShape(RoundedRectangle(cornerRadius: 6))
        
    } else {
        // 🎯 Fallback to the System Icon
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.tint)
    }
}





struct ImageGenerator {
    
    
    
    
    static func processResult(from url: URL, for option: WorkoutOption) {
        do {
            let data = try Data(contentsOf: url)
            option.imageData = data
        } catch {
            print("Failed to process Image Playground result: \(error)")
        }
    }
}





