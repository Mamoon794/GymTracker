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

func isMaxWeightRecord(_ exercise: Exercise) -> Bool {
    guard let stats = exercise.getWorkoutStat(),
            let globalMaxSet = stats.maxWeightStat else { return false }
    
    return exercise.id == globalMaxSet.id
}

func isOneRepMaxRecord(_ exercise: Exercise) -> Bool {
    guard let stats = exercise.getWorkoutStat(),
            let globalPRSet = stats.maxOneRepStat else { return false }
    
    return exercise.id == globalPRSet.id
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
            
            HStack{
                if isMaxWeightRecord(exercise) {
                    Text("PR")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                }
                if isOneRepMaxRecord(exercise) {
                    Text("1RM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 0.0)) 
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                }
            }
            .id(exercise.getSourceWorkout()?.lastUpdated ?? Date())
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





enum DataMigrator {
    static func fixMissingMonths(context: ModelContext) {
        let predicate = #Predicate<Exercise> { exercise in
            exercise.monthly == nil
        }
        
        let descriptor = FetchDescriptor(predicate: predicate)
        
        guard let orphans = try? context.fetch(descriptor), !orphans.isEmpty else {
            return // Nothing to fix
        }
        
        print("Found \(orphans.count) exercises with missing months. Fixing...")
        
        // 3. Cache existing months
        var monthCache: [String: MonthlyWorkout] = [:]
        
        let monthDescriptor = FetchDescriptor<MonthlyWorkout>()
        if let existingMonths = try? context.fetch(monthDescriptor) {
            for m in existingMonths {
                monthCache[m.idString] = m
            }
        }
        
        // 4. Assign orphans
        for exercise in orphans {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: exercise.date)
            let month = calendar.component(.month, from: exercise.date)
            let key = "\(year)-\(month)"
            
            if let existing = monthCache[key] {
                exercise.monthly = existing
            } else {
                let newMonth = MonthlyWorkout(date: exercise.date)
                context.insert(newMonth)
                
                exercise.monthly = newMonth
                
                monthCache[key] = newMonth
            }
        }
        
        try? context.save()
        print("Fixed all missing months.")
    }
}
