//
//  PersonCustomization.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-12-30.
//


import SwiftUI
import SwiftData
import PhotosUI


struct PersonCustomization: View {
    // 1. Fetch your options from the database
    @Query private var allWorkoutOptions: [WorkoutOption]
    @Environment(\.modelContext) private var modelContext
    @State private var draftNames: [PersistentIdentifier: String] = [:]
    @State private var selectedFilter: WorkoutCategory? = nil
    
    
    private var filteredOptions: [WorkoutOption] {
        if let selectedFilter {
            return allWorkoutOptions.filter { $0.category == selectedFilter }
        } else {
            return allWorkoutOptions
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // 1. Customize Workouts Bar
                    NavigationLink(destination: WorkoutSettingsView()) {
                        Label {
                            Text("Customize Exercises")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "dumbbell.fill")
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 2. Customize Routines Bar
                    NavigationLink(destination: RoutineSettingsView()) {
                        Label {
                            Text("Customize Routines")
                                .font(.headline)
                        } icon: {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(.emerald500)
                        }
                        .padding(.vertical, 4)
                    }
                } 
            }
            .navigationTitle("Configuration")
        }
    }
    
    
    private func isNameValid(_ name: String, for option: WorkoutOption) -> Bool {
        let cleaned = name.trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return false }
        
        // Check if the name exists elsewhere
        let isDuplicate = allWorkoutOptions.contains {
            $0.name.lowercased() == cleaned.lowercased() && $0.id != option.id
        }
        
        return !isDuplicate
    }
}



struct WorkoutSettingsView: View {
    // Queries and State necessary for this specific screen
    @Query(sort: \WorkoutOption.name) private var allOptions: [WorkoutOption]
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext

    private var filteredOptions: [WorkoutOption] {
        if searchText.isEmpty {
            return allOptions
        } else {
            return allOptions.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack{
            List {
                ForEach(filteredOptions) { option in
                    NavigationLink(destination: WorkoutDetailView(workoutOption: option)) {
                        HStack {
                            exerciseIcon(imageData: option.getImageData(), iconName: option.getImage())
                                .foregroundStyle(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text(option.name)
                                .font(.body)
                            
                            Spacer()
                            
                            Text(option.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteOption)
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search Exercises")
        }
    }

    private func deleteOption(at offsets: IndexSet) {
        for index in offsets {
            let option = filteredOptions[index]
            modelContext.delete(option)
        }
        try? modelContext.save()
    }
}


struct WorkoutDetailView: View {
    @Bindable var workoutOption: WorkoutOption // Changed to @Bindable for easier binding
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingImage = false

    var body: some View {
        List {
            Section("Exercise Details") {
                HStack {
                    // 1. Display the Custom Image or System Icon
                    if let data = workoutOption.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: workoutOption.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32) // Keep system icon slightly smaller
                            .foregroundStyle(.blue)
                    }
                    
                    TextField("Name", text: Binding(
                        get: { workoutOption.name },
                        set: { newName in
                            workoutOption.name = newName
                            // Update stats name as well
                            workoutOption.stats?.workoutName = newName
                        }
                    ))
                    .font(.headline)
                    .padding(.leading, 8)
                }
            }

            Section("Image") {
                HStack {
                    // Show current image preview
                    if let data = workoutOption.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.trailing, 8)
                    }
                    
                    VStack(alignment: .leading) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(workoutOption.imageData == nil ? "Upload Image" : "Change Image", 
                                  systemImage: "photo.badge.plus")
                        }
                        
                        if workoutOption.imageData != nil {
                            Button(role: .destructive) {
                                withAnimation {
                                    workoutOption.imageData = nil
                                }
                                try? modelContext.save()
                            } label: {
                                Text("Remove Image")
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    uploadImage(newItem)
                }
                
                if isLoadingImage {
                    ProgressView()
                }
            }
            
            Section("Category") {
                Picker("Category", selection: $workoutOption.category) {
                    ForEach(WorkoutCategory.allCases) { cat in
                        HStack {
                            Image(systemName: cat.icon)
                            Text(cat.rawValue)
                        }
                        .tag(cat)
                    }
                }
                .pickerStyle(.navigationLink)
            }
            
            Section("Equipment") {
                Toggle(isOn: $workoutOption.isBarbellWeight) {
                    Label("Barbell Weight", systemImage: "dumbbell.fill")
                }
            }
        }
        .navigationTitle(workoutOption.name)
        .navigationBarTitleDisplayMode(.inline)
        // Auto-save triggers
        
        .onDisappear {
            try? modelContext.save()
        }
        .onChange(of: workoutOption.category) { _, _ in try? modelContext.save() }
        .onChange(of: workoutOption.isBarbellWeight) { _, _ in try? modelContext.save() }
    }

    private func uploadImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isLoadingImage = true
        
        Task {
            // 1. Load the raw data
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                // 2. Resize and Compress
                // This ensures the image is exactly 40x40 points (so 80x80 or 120x120 pixels on Retina)
                if let compressedData = resizeAndCompressImage(image: uiImage, targetSize: CGSize(width: 40, height: 40)) {
                    
                    await MainActor.run {
                        // 3. Save to Model
                        workoutOption.imageData = compressedData
                        try? modelContext.save()
                        isLoadingImage = false
                        selectedPhotoItem = nil // Reset picker
                    }
                }
            } else {
                await MainActor.run { isLoadingImage = false }
            }
        }
    }
    
    // Helper function to resize image to save space
    private func resizeAndCompressImage(image: UIImage, targetSize: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        // Convert to JPEG with 0.7 compression (good balance of quality/size)
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}

struct RoutineSettingsView: View {
    @Query(sort: \WorkoutRoutine.name) private var allRoutines: [WorkoutRoutine]
    @Query(sort: \WorkoutOption.name) var allOptions: [WorkoutOption]
    @State private var searchText: String = ""
    @Environment(\.modelContext) private var modelContext

     private var filteredRoutines: [WorkoutRoutine] {
        if searchText.isEmpty {
            return allRoutines
        } else {
            return allRoutines.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }


    var body: some View {
        NavigationStack{
            List {
                ForEach(filteredRoutines){ routine in
                    NavigationLink(destination: RoutineDetailView(routine: routine, allOptions: allOptions)) {
                        HStack{
                            Text(routine.name)
                            Spacer()
                            
                            Text("\(routine.items.count) Exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.emerald500.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .onDelete(perform: deleteRoutine)
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search Routines")
        }
    }

    private func deleteRoutine(at offsets: IndexSet) {
        for index in offsets {
            let routine = filteredRoutines[index]
            modelContext.delete(routine)
        }
        try? modelContext.save()
    }
}



struct RoutineDetailView: View {
    let routine: WorkoutRoutine
    let allOptions: [WorkoutOption]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedOptions: [WorkoutOption] = []

    var sortedItems: [RoutineItem] {
        routine.items.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        List {
            Section("Routine Details") {
                TextField("Routine Name", text: Binding(
                    get: { routine.name },
                    set: { routine.name = $0 }
                ))
                .font(.headline)
            }

            Section {
                SelectExercise(allOptions: allOptions, selectedOptions: $selectedOptions)
            } header: {
                Text("Add Exercises")
            }
            
            Section("Exercises") {
                if routine.items.isEmpty {
                    Text("No exercises added")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedItems) { item in
                        HStack {
                            exerciseIcon(imageData: item.workoutOption?.getImageData(), iconName: item.workoutOption?.getImage() ?? WorkoutCategory.chest.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text(item.workoutOption?.name ?? "Unknown")
                                .font(.body)
                            
                            Spacer()
                            
                            Text(item.workoutOption?.category.rawValue ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: moveItem)
                }
            }
            
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            
            selectedOptions = routine.items
                .sorted { $0.orderIndex < $1.orderIndex }
                .compactMap { $0.workoutOption }
        }
        .onChange(of: selectedOptions) { _, newValue in
            updateRoutineItems(newValue)
            try? modelContext.save()
        }
        .toolbar {
            // 4. Required to see the "handlebars" for moving
            EditButton()
        }
    }
    
    private func updateRoutineItems(_ newSelection: [WorkoutOption]) {
        let selectedIDs = newSelection.map { $0.id }
        
        let itemsToRemove = routine.items.filter { item in
            guard let option = item.workoutOption else { return true } // Remove orphans
            return !selectedIDs.contains(option.id)
        }
        
        for item in itemsToRemove {
            if let index = routine.items.firstIndex(of: item) {
                routine.items.remove(at: index)
            }
            modelContext.delete(item)
        }
        
        for (index, option) in newSelection.enumerated() {
            // Check if a RoutineItem already exists for this exercise
            if let existingItem = routine.items.first(where: { $0.workoutOption?.id == option.id }) {
                existingItem.orderIndex = index
            } else {
                let newItem = RoutineItem(orderIndex: index, workoutOption: option)
                newItem.routine = routine
                routine.items.append(newItem)
                modelContext.insert(newItem)
            }
        }
    }

    private func moveItem(from source: IndexSet, to destination: Int) {
        var items = sortedItems
        
        items.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in items.enumerated() {
            item.orderIndex = index
        }
        
        try? modelContext.save()
    }
}



