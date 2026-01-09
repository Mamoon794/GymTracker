import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @State private var newReps: String = ""
    @State private var newWeight: String = ""
    @State private var useKg: Bool = false
    var isBarbell: Bool {
        exercise.getIsBarbellWeight()
    }
    
    var sortedIndices: [Int] {
        exercise.sets.indices.sorted {
            exercise.sets[$0].orderIndex < exercise.sets[$1].orderIndex
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Sets")) {
                ForEach(sortedIndices, id: \.self) { idx in
                    ExerciseRow(
                        setNumber: exercise.sets[idx].orderIndex + 1,
                        set: $exercise.sets[idx]
                    )
                }
                .onDelete(perform: deleteSet)
                .onMove(perform: move)
            }
            

            Section(header: Text("Add Set")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Reps", text: $newReps).keyboardType(.numberPad)
                        TextField(useKg ? "Weight (kg)" : "Weight (lbs)", text: $newWeight).keyboardType(.decimalPad)
                    }

                    HStack(spacing: 20) {
                        // Toggle for Lbs vs Kg
                        Toggle("Use KG", isOn: $useKg).labelsHidden()
                        Text(useKg ? "KG" : "LB").font(.caption).bold()

                        Divider().frame(height: 20)

                        // The "Tick Mark" for Barbell formula
                        if (isBarbell){
                            Label("Is Barbell Weight", systemImage: "dumbbell.fill")
                                .foregroundStyle(.emerald500)
                        }
                    }

                    Button(action: addSet) {
                        Text("Add Set")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAdd)
                }
                
            }
        }
        .navigationTitle(exercise.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        
        
        
    }
    func move(from source: IndexSet, to destination: Int) {
        var visibleSets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
        
        visibleSets.move(fromOffsets: source, toOffset: destination)
        
        for (index, set) in visibleSets.enumerated() {
            set.orderIndex = index
        }
    }

    private var canAdd: Bool {
        Int(newReps) != nil && Double(newWeight) != nil
    }

    private func addSet() {
        guard let reps = Int(newReps), var weight = Double(newWeight) else { return }
        
        if useKg{
            weight = weight * 2.205
        }
        if isBarbell{
            weight = (weight * 2) + 45
        }
        
        let newSet = ExerciseSet(reps: reps, weight: weight, orderIndex: exercise.totalSets)
        exercise.sets.append(newSet)
        
        newReps = ""
        newWeight = ""
    }
    
    private func deleteSet(at offsets: IndexSet) {
        for offset in offsets {
            let actualIndex = sortedIndices[offset]
            exercise.sets.remove(at: actualIndex)
        }
        
        exercise.synchronizeIndices()
    }

}


struct ExerciseRow: View {
    var setNumber: Int
    @Binding var set: ExerciseSet
    
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Spacer()
            
            Stepper(value: $set.reps, in: 0...200) {
                Text("Reps: \(set.reps)")
            }
            .frame(maxWidth: 170)
            
            Spacer()
            
            Text("\(set.weight, specifier: "%.1f") lbs")
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .contextMenu {
                    Button("+2.5 lbs") { set.weight += 2.5 }
                    Button("+5 lbs") { set.weight += 5 }
                    Button("-2.5 lbs") { set.weight -= 2.5 }
                    Button("-5 lbs") { set.weight -= 5 }
                }
        }
    }
}


#Preview{
    ExerciseDetailView(exercise: Exercise(sourceWorkout: WorkoutOption(name: "test", category: WorkoutCategory.chest, image: "figure.strengthtraining.traditional", isBarbellWeight: true)))
}
