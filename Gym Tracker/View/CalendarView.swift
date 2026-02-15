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
    @Query(sort: [SortDescriptor(\MonthlyWorkout.year, order: .forward), SortDescriptor(\MonthlyWorkout.month, order: .forward)]) 
    private var monthlyWorkouts: [MonthlyWorkout]
    

    @State private var selectedDate: DateComponents? = Calendar.current.dateComponents([.day, .month, .year], from: .now)
    @Binding var isBarHidden: Bool
    
    @State private var viewMode: ViewMode = .calendar
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext
    


        
    enum ViewMode: String, CaseIterable {
        case calendar = "Calendar"
        case list = "Exercises"
    }
    
    // Filter exercises based on the selected calendar day
    var filteredExercises: [Exercise] {
        guard let selectedDate = selectedDate?.date else { return [] }
        return monthlyWorkouts.flatMap { $0.getExercises(date: selectedDate) }
    }
    
    var historyData: [DaySection] {
        var allDays: [DaySection] = []
        
        // Iterate through all months to gather exercises
        for summary in monthlyWorkouts {
            // A. Filter exercises by search text
            let matches = summary.exercises.filter { exercise in
                searchText.isEmpty ||
                exercise.getName().localizedCaseInsensitiveContains(searchText)
            }
            
            if matches.isEmpty { continue }
            
            // B. Group this month's exercises by Day
            let groupedByDay = Dictionary(grouping: matches) { exercise in
                Calendar.current.startOfDay(for: exercise.date)
            }
            
            // C. Convert to DaySection objects
            let days = groupedByDay.map { (date, exercises) in
                // We use 'dailyGroups' as the variable name because your UI code uses it
                DaySection(date: date, dailyGroups: exercises)
            }
            
            allDays.append(contentsOf: days)
        }
        
        // D. Sort all days (Newest first)
        return allDays.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewMode == .calendar {
                    WorkoutCalendar(monthlyWorkouts: monthlyWorkouts, selectedDate: $selectedDate)
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
    let monthlyWorkouts: [MonthlyWorkout]
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
        let allDates = monthlyWorkouts.flatMap { summary in
            summary.exercises.map {
                Calendar.current.dateComponents([.year, .month, .day], from: $0.date)
            }
        }
        
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

        // Add a dot to days with workouts
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let year = dateComponents.year,
                              let month = dateComponents.month,
                              let day = dateComponents.day else { return nil }
            
            guard let monthSummary = parent.monthlyWorkouts.first(where: {
                $0.year == year && $0.month == month
            }) else {
                return nil
            }
            
            let hasWorkout = monthSummary.exercises.contains { exercise in
                let exerciseDay = Calendar.current.component(.day, from: exercise.date)
                return exerciseDay == day
            }

            return hasWorkout ? .default(color: .systemGreen, size: .medium) : nil
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            parent.selectedDate = dateComponents
        }
    }
}


#Preview {
    CalendarView(isBarHidden: .constant(true))
}

