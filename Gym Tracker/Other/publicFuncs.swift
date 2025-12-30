//
//  publicFuncs.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-29.
//

import SwiftUI
import SwiftData

func exerciseRow(_ exercise: Exercise) -> some View{
    HStack(spacing: 12) {
        Image(systemName: exercise.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .foregroundStyle(.tint)

        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            Text("Sets: \(exercise.totalSets)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        Spacer()
    }
    .padding(.vertical, 6)
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
    @State private var newName = ""
    
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
                    showingRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button {
                    ops.duplicate(exercise)
                    triggerSuccessHaptic()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
            }
        }
        .alert("Rename Exercise", isPresented: $showingRenameAlert) {
            TextField("Exercise Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                ops.rename(exercise, to: newName)
            }
        }
    }
}
