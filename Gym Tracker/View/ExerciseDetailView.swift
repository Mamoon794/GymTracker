import SwiftUI



struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    
    @State private var newReps: String = ""
    @State private var newWeight: String = ""
    @State private var useKg: Bool = false
    @State private var isBarbell: Bool = false

    var body: some View {
        List {
            Section(header: Text("Sets")) {
                ForEach($exercise.sets) { $set in
                    ExerciseRow(
                        setNumber: (exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1,
                        set: $set
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
                        Toggle(isOn: $isBarbell) {
                            Label("Is Barbell Weight", systemImage: "dumbbell.fill")
                        }
                        .toggleStyle(.button)
                        .tint(.emerald500)
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
    func move(indexSet: IndexSet, int: Int){
        exercise.sets.move(fromOffsets: indexSet, toOffset: int)
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
        
        let newSet = ExerciseSet(reps: reps, weight: weight)
        exercise.sets.append(newSet)
        
        newReps = ""
        newWeight = ""
    }
    
    private func deleteSet(at offsets: IndexSet) {
        exercise.sets.remove(atOffsets: offsets)
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
                    Button("Reset weight") { set.weight = 0 }
                }
        }
    }
}


#Preview{
    ExerciseDetailView(exercise: Exercise(name: "Test", imageName: "figure.strengthtraining.traditional"))
}
