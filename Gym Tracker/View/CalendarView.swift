//
//  CalendarView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData


struct DaySection: Identifiable {
    let id = UUID()
    let date: Date
    let dailyGroups: [Exercise] // Variable name matches your UI code
}


struct CalendarView: View {

    @Query(sort: \Exercise.date, order: .reverse) var allExercises: [Exercise]
    

    @State private var selectedDate: DateComponents? = Calendar.current.dateComponents([.day, .month, .year], from: .now)
    @Binding var isBarHidden: Bool
    
    @State private var viewMode: ViewMode = .calendar
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext
    


        
    enum ViewMode: String, CaseIterable {
        case calendar = "Calendar"
        case list = "Exercises"
    }
    
    var workoutDays: Set<DateComponents> {
        let components = allExercises.map { exercise in
            // Ask for Year, Month, Day
            var dc = Calendar.current.dateComponents([.year, .month, .day], from: exercise.date)
            
            dc.isLeapMonth = nil
            return dc
        }
        return Set(components)
    }
    
    var filteredExercises: [Exercise] {
        guard let selectedDate = selectedDate?.date else { return [] }
        
        return allExercises.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    
    var historyData: [DaySection] {
        let filtered = searchText.isEmpty ? allExercises : allExercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if filtered.isEmpty { return [] }

        var sections: [DaySection] = []
        
        var currentBatch: [Exercise] = []
        var currentDate: Date? = nil
        
        for exercise in filtered {
            let exerciseDay = Calendar.current.startOfDay(for: exercise.date)
            
            // If it's the first item, set the date
            if currentDate == nil {
                currentDate = exerciseDay
            }
            
            // If this exercise belongs to the current batch, add it
            if exerciseDay == currentDate {
                currentBatch.append(exercise)
            } else {
                if let date = currentDate {
                    sections.append(DaySection(date: date, dailyGroups: currentBatch))
                }
                
                currentDate = exerciseDay
                currentBatch = [exercise]
            }
        }
        
        if let date = currentDate, !currentBatch.isEmpty {
            sections.append(DaySection(date: date, dailyGroups: currentBatch))
        }
        
        return sections
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewMode == .calendar {
                    WorkoutCalendar(workoutDays: workoutDays, selectedDate: $selectedDate)
                        .padding(.horizontal, 5)
                        .frame(height: 490)
            
                    if (isBarHidden){
                        List {
                            
                            Section(header: HStack {
                                Text("Workouts for \(selectedDate?.date?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                Spacer()
                                Text("\(filteredExercises.count)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.gradient)
                                    .clipShape(Capsule())
                            }) {
                                if filteredExercises.isEmpty {
                                    ContentUnavailableView("No Workouts", systemImage: "dumbbell", description: Text("Rest day!"))
                                } else {
                                    ForEach(filteredExercises) { exercise in
                                        ExerciseRowNav(exercise: exercise)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                    else{
                        Spacer()
                    }
                    
                    
                } else {
                    List {
                        ForEach(historyData, id: \.date) { group in
                            Section(header: HStack {
                                Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("\(group.dailyGroups.count)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.gradient)
                                    .clipShape(Capsule())
                            }) {
                                
                                ForEach(group.dailyGroups) { exercise in
                                    ExerciseRowNav(exercise: exercise)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
                    
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
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
    let workoutDays: Set<DateComponents>
    @Binding var selectedDate: DateComponents?

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
        // 1. Set the initial selection
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        selection.selectedDate = selectedDate 
        calendarView.selectionBehavior = selection
        
        calendarView.delegate = context.coordinator
        
        // 2. Set the visible date to now (or selected date) so it doesn't start in 1970
        if let date = selectedDate?.date {
            calendarView.visibleDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        }
        
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // 3. Update the Coordinator's data source first
        context.coordinator.parent = self
        
        // 4. Update the Selection State (Programmatic selection support)
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            if selection.selectedDate != selectedDate {
                selection.setSelected(selectedDate, animated: true)
            }
        }
        
        let allDates = Array(workoutDays)
        uiView.reloadDecorations(forDateComponents: allDates, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: WorkoutCalendar

        init(parent: WorkoutCalendar) {
            self.parent = parent
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            // Normalize the components to ensure we match what's in the Set
            // (The Set contains Year/Month/Day)
            var searchComponents = DateComponents()
            searchComponents.year = dateComponents.year
            searchComponents.month = dateComponents.month
            searchComponents.day = dateComponents.day
            
            searchComponents.isLeapMonth = nil
            
            if parent.workoutDays.contains(searchComponents) {
                return .default(color: .systemGreen, size: .medium)
            }
            return nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
        }
        
        // Add this to handle "deselection" if user taps the same date again (optional)
        func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
            return true
        }
    }
}


#Preview {
    CalendarView(isBarHidden: .constant(true))
}

