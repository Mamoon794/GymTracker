import SwiftUI
import SwiftData


enum FocusedField {
    case reps, weight
}

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @State private var newReps: String = ""
    @State private var newWeight: String = ""
    @State private var useKg: Bool = false
    @State private var showHistory = false
    @State private var showPlateCalc: Bool = false
    @FocusState private var focusedField: FocusedField?
    
    var isBarbell: Bool {
        exercise.getIsBarbellWeight()
    }
    
    var sortedIndices: [Int] {
        exercise.sets.indices.sorted {
            exercise.sets[$0].orderIndex < exercise.sets[$1].orderIndex
        }
    }
    
    var body: some View {
        HStack{
            if (isBarbell){
                Spacer()
                Toggle(isOn: $showPlateCalc) {
                    Label("Single Plate", systemImage: "dumbbell.fill")
                }
                .tint(isBarbell ? .emerald500 : .accentColor)
                .controlSize(.small)
                .labelsHidden()
                Text("Single Plate").font(.caption).bold()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
        List {
            Section(header: Text("Sets")) {
                ForEach(sortedIndices, id: \.self) { idx in
                    ExerciseRow(
                        setNumber: exercise.sets[idx].orderIndex + 1,
                        set: $exercise.sets[idx],
                        exercise: exercise,
                        showPlateCalc: showPlateCalc
                    )
                }
                .onDelete(perform: deleteSet)
                .onMove(perform: move)
            }
            

            Section(header: Text("Add Set")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Reps", text: $newReps).keyboardType(.numberPad)
                            .focused($focusedField, equals: .reps)
                        
                        TextField(useKg ? "Weight (kg)" : "Weight (lbs)", text: $newWeight).keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                // 3. Only show content if Weight is focused
                                if focusedField == .weight {
                                    Spacer()
                                    
                                    Button("+") { newWeight += "+" }
                                    Button("-") { newWeight += "-" }
                                    Button("*") { newWeight += "*" }
                                    Button("/") { newWeight += "/" }
                                    
                                    Button("Done") {
                                        focusedField = nil // Clean way to dismiss keyboard
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 20) {
                        // Toggle for Lbs vs Kg
                        Toggle("Use KG", isOn: $useKg).labelsHidden()
                        Text("KG").font(.caption).bold()

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
        .navigationTitle(exercise.getName())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            // Safely unwrap the parent WorkoutOption
            ExerciseHistorySheet(exercise: exercise)
                    .presentationDetents([.medium, .large])
        }
        .onAppear {
            if let lastSet = exercise.sets.last, lastSet.weight > 0 {
                if isBarbell {
                    let calculatedWeight = (lastSet.weight - 45) / 2
                    newWeight = String(format: "%.1f", calculatedWeight)
                } else {
                    newWeight = String(format: "%.1f", lastSet.weight)
                }
            }
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
        Int(newReps) != nil
    }

    private func addSet() {
        guard let reps = Int(newReps) else { return }
        
        var weight = parseWeight(newWeight) ?? 0.0
        
        if useKg{
            weight = weight * 2.205
        }
        if isBarbell{
            weight = (weight * 2) + 45
        }
        
        let newSet = ExerciseSet(reps: reps, weight: weight, orderIndex: exercise.totalSets)
        exercise.sets.append(newSet)
        
        newReps = ""
        if (weight == 0){
            newWeight = ""
        }
        
        exercise.getSourceWorkout().lastUpdated = Date.now
    }
    
    private func deleteSet(at offsets: IndexSet) {
        for offset in offsets {
            let actualIndex = sortedIndices[offset]
            exercise.sets.remove(at: actualIndex)
        }
        
        exercise.synchronizeIndices()
        exercise.getSourceWorkout().lastUpdated = Date.now
    }

    private func parseWeight(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // Try to parse as simple number first
        if let number = Double(trimmed) {
            return number
        }
        
        let complexRegex = "^[0-9.]+(?:[+\\-*/][0-9.]+)*$"
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", complexRegex)
        guard predicate.evaluate(with: trimmed) else {
            return 0.0
        }
        
       
        
        // Try to evaluate as expression
        
        let expression = NSExpression(format: trimmed)
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }
   
        
        return 0.0

    }

}


struct ExerciseRow: View {
    var setNumber: Int
    @Binding var set: ExerciseSet
    var exercise: Exercise
    var showPlateCalc: Bool
    
    var displayWeight: String {
        if showPlateCalc {
            
            let plates = (set.weight - 45.0) / 2.0
            
            return plates >= 0 ? String(format: "%.1f", plates) : "0"
        } else {
            return String(format: "%.1f", set.weight)
        }
    }
    
    
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
            .onChange(of: set.reps) { _, _ in
                exercise.getSourceWorkout().lastUpdated = Date.now
            }
            
            Spacer()
            
            Text("\(displayWeight) \(showPlateCalc ? "side" : "lbs")")
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .contextMenu {
                    Button("+2.5 lbs") { updateWeight(2.5) }
                    Button("+5 lbs") { updateWeight(5) }
                    Button("-2.5 lbs") { updateWeight(-2.5) }
                    Button("-5 lbs") { updateWeight(-5) }
                }
        }
    }
    
    private func updateWeight(_ weight: Double){
        set.weight += weight
        exercise.getSourceWorkout().lastUpdated = Date.now
        
    }
}


#Preview{
    ExerciseDetailView(exercise: Exercise(sourceWorkout: WorkoutOption(name: "test", category: WorkoutCategory.chest)))
}

