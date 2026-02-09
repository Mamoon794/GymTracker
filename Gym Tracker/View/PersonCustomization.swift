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
    @Bindable var workoutOption: WorkoutOption
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var isEditingTimer = false
    
    // 1. Add State to hold the loaded image
    @State private var loadedImage: UIImage?

    var body: some View {
        List {
            Section("Exercise Details") {
                HStack {
                    // 2. Use the State variable (Fast) instead of converting Data (Slow)
                    if let uiImage = loadedImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        // Fallback System Icon
                        Image(systemName: workoutOption.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.blue)
                    }
                    
                    TextField("Name", text: Binding(
                        get: { workoutOption.name },
                        set: { newName in
                            workoutOption.name = newName
                            workoutOption.stats?.workoutName = newName
                        }
                    ))
                    .font(.headline)
                    .padding(.leading, 8)
                }
            }

            Section("Image") {
                HStack {
                    if let uiImage = loadedImage {
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
                                    loadedImage = nil // Clear state immediately
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
            
            // ... (Category and Equipment sections remain the same) ...
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

            // 3. Add your Rest Timer Section here properly
            restTimerSection
        }
        .navigationTitle(workoutOption.name)
        .navigationBarTitleDisplayMode(.inline)
        
        // 4. Load the image when view appears
        .onAppear {
            if let data = workoutOption.imageData {
                self.loadedImage = UIImage(data: data)
            }
        }
        // 5. Update image if the underlying data changes (e.g. undo/redo)
        .onChange(of: workoutOption.imageData) { _, newData in
            if let data = newData {
                self.loadedImage = UIImage(data: data)
            } else {
                self.loadedImage = nil
            }
        }
        
        // Auto-save triggers
        .onDisappear { try? modelContext.save() }
        .onChange(of: workoutOption.category) { _, _ in try? modelContext.save() }
        .onChange(of: workoutOption.isBarbellWeight) { _, _ in try? modelContext.save() }
        // 6. FIX: Add the missing dot (.) here
        .onChange(of: workoutOption.timerSeconds) { _, _ in try? modelContext.save() }
    }

    private func uploadImage(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isLoadingImage = true
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                if let compressedData = resizeAndCompressImage(image: uiImage, targetSize: CGSize(width: 40, height: 40)) {
                    
                    await MainActor.run {
                        // Update Model
                        workoutOption.imageData = compressedData
                        // Update View State immediately so UI feels snappy
                        loadedImage = UIImage(data: compressedData) 
                        try? modelContext.save()
                        isLoadingImage = false
                        selectedPhotoItem = nil
                    }
                }
            } else {
                await MainActor.run { isLoadingImage = false }
            }
        }
    }

    private var restTimerSection: some View {
        Section("Rest Timer") {
            // 1. The Display Row (Clickable)
            Button {
                withAnimation {
                    isEditingTimer.toggle() // You need to add this State variable
                }
            } label: {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.blue)
                    
                    Text("Rest Duration")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Shows "1m 30s" normally, turns blue when editing
                    Text(formatDuration(workoutOption.timerSeconds))
                        .font(.body.bold())
                        .foregroundStyle(isEditingTimer ? .blue : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isEditingTimer ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .buttonStyle(.plain) // Removes standard button fading
            
            // 2. The Wheel Picker (Conditional)
            if isEditingTimer {
                HStack {
                    Spacer()
                    TimerWheelPicker(seconds: $workoutOption.timerSeconds)
                    Spacer()
                }
                // Ensure data saves when we stop scrolling
                .onChange(of: workoutOption.timerSeconds) { _, _ in
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        if seconds == 0 { return "Off" }
        let totalSeconds = Int(seconds)
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        if min > 0 {
            return sec > 0 ? "\(min)m \(sec)s" : "\(min)m"
        } else {
            return "\(sec)s"
        }
    }
    
    private func resizeAndCompressImage(image: UIImage, targetSize: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}


struct TimerWheelPicker: View {
    @Binding var seconds: Double
    
    // Convert total seconds to minutes index (0-10)
    private var minutesBinding: Binding<Int> {
        Binding(
            get: { Int(seconds) / 60 },
            set: { newMinute in
                let currentSeconds = Int(seconds) % 60
                seconds = Double((newMinute * 60) + currentSeconds)
            }
        )
    }
    
    // Convert total seconds to seconds index (0-59)
    private var secondsBinding: Binding<Int> {
        Binding(
            get: { Int(seconds) % 60 },
            set: { newSecond in
                let currentMinutes = Int(seconds) / 60
                seconds = Double((currentMinutes * 60) + newSecond)
            }
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // MINUTES WHEEL
            Picker("Minutes", selection: minutesBinding) {
                ForEach(0..<11) { min in 
                    Text("\(min) min").tag(min)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped() // Keeps the wheel from overlapping
            
            // SECONDS WHEEL
            Picker("Seconds", selection: secondsBinding) {
                // You can change `0..<60` to `stride(from: 0, to: 60, by: 15)`
                // if you only want 0, 15, 30, 45 options.
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { sec in
                    Text("\(sec) sec").tag(sec)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()
        }
        .frame(height: 150) // Restrict height so it doesn't expand too much
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


