//
//  CalendarView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData



struct CalendarView: View {
    @Query(sort: \Exercise.date, order: .reverse) private var allExercises: [Exercise]
    @State private var selectedDate: DateComponents? = Calendar.current.dateComponents([.day, .month, .year], from: .now)
    @Binding var isBarHidden: Bool
    
    @State private var viewMode: ViewMode = .calendar
    @State private var searchText = ""

    // 1. Filter the list based on search text
    var searchedExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        } else {
            return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
        
    enum ViewMode: String, CaseIterable {
        case calendar = "Calendar"
        case list = "List"
    }
    
    // Filter exercises based on the selected calendar day
    var filteredExercises: [Exercise] {
        guard let selectedDate = selectedDate?.date else { return [] }
        return allExercises.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var groupedByDate: [(date: Date, exercises: [Exercise])] {
        let grouped = Dictionary(grouping: searchedExercises) { (exercise) -> Date in
            Calendar.current.startOfDay(for: exercise.date)
        }
        // Sort so the most recent dates appear first
        return grouped.map { (date: $0.key, exercises: $0.value) }
                      .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isBarHidden.toggle()
                    }
                }
                
                if viewMode == .calendar {
                    Spacer().frame(height: 20)
                    WorkoutCalendar(exercises: allExercises, selectedDate: $selectedDate)
                        .frame(height: 400)
                        .padding()
                    
                    List {
                        
                        Section("Workouts for \(selectedDate?.date?.formatted(date: .abbreviated, time: .omitted) ?? "")") {
                            if filteredExercises.isEmpty {
                                ContentUnavailableView("No Workouts", systemImage: "dumbbell", description: Text("Rest day!"))
                            } else {
                                ForEach(filteredExercises) { exercise in
                                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                        exerciseRow(exercise)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    
                } else {
                    VStack{
                        Spacer()
                        searchBar
                        List {
                            
                            ForEach(groupedByDate, id: \.date) { group in
                                // Use the date as the Section Header
                                Section(header: Text(group.date.formatted(date: .abbreviated, time: .omitted))) {
                                    ForEach(group.exercises) { exercise in
                                        NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                            exerciseRow(exercise)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                    
                }
                
            }
        
            
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(red: 0.69, green: 0.73, blue: 0.78))
            
            TextField("Search exercises...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(red: 0.69, green: 0.73, blue: 0.78))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
        
    }
}




struct WorkoutCalendar: UIViewRepresentable {
    let exercises: [Exercise]
    @Binding var selectedDate: DateComponents?

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
        // Setup Delegate for decorations and selection
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        calendarView.delegate = context.coordinator
        
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Refresh decorations if data changes
        let workoutDates = exercises.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.date) }
        uiView.reloadDecorations(forDateComponents: workoutDates, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: WorkoutCalendar

        init(parent: WorkoutCalendar) {
            self.parent = parent
        }

        // Add a dot to days with workouts
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let hasWorkout = parent.exercises.contains {
                Calendar.current.isDate($0.date, inSameDayAs: dateComponents.date ?? Date.distantPast)
            }
            return hasWorkout ? .default(color: .systemGreen, size: .medium) : nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
        }
    }
}


#Preview {
    CalendarView(isBarHidden: .constant(false))
}

