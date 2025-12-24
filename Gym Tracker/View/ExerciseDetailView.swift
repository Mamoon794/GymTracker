import SwiftUI



struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    
    @State private var newReps: String = ""
    @State private var newWeight: String = ""

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
                HStack {
                    TextField("Reps", text: $newReps)
                        .keyboardType(.numberPad)
                    TextField("Weight (kg)", text: $newWeight)
                        .keyboardType(.decimalPad)
                    Button("Add") { addSet() }
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
        guard let reps = Int(newReps), let weight = Double(newWeight) else { return }
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
            
            Text("\(set.weight, specifier: "%.1f") kg")
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
                .contextMenu {
                    Button("+2.5 kg") { set.weight += 2.5 }
                    Button("+5 kg") { set.weight += 5 }
                    Button("Reset weight") { set.weight = 0 }
                }
        }
    }
}

