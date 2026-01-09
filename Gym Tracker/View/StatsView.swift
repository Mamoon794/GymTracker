//
//  StatsView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import SwiftData
import Charts



struct StatsView: View {
    @Query(sort: \Exercise.sourceWorkout?.name, order: .forward)
    private var allExercises: [Exercise]
    let allWorkoutOptions: [WorkoutOption]
    @State private var selectedWorkoutName: String = "Bench Press"
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Exercise Breakdown Chart
                    chartCard(title: "Exercise Frequency") {
                        exerciseFrequencyChart()
                    }
                    
                    // 2. One Rep Max Progress
                    chartCard(title: "One Rep Max Progress") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Picker("Select Exercise", selection: $selectedWorkoutName) {
                                ForEach(allWorkoutOptions, id: \.name) { option in
                                    Text(option.name).tag(option.name)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.emerald500)
                            .buttonStyle(.bordered)

                            oneRepMaxLineChart(for: selectedWorkoutName)
                        }
                    }
                    
                    // 3. Quick Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        statSummaryCard(
                            label: "Total Workouts",
                            value: "\(allExercises.count)",
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Volume (kg)",
                            value: String(format: "%.0f", totalVolume),
                            color: .emerald500
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Separate Action & Logic Functions
    
    private func exerciseFrequencyChart() -> some View {
        Chart(topExerciseFrequencyData, id: \.name) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Exercise", item.name)
            )
            // 🎯 1. This generates the colors and the legend automatically
            .foregroundStyle(by: .value("Exercise", item.name))
            .cornerRadius(4)
            
            .annotation(position: .trailing) {
                Text("\(item.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 240)
        .chartXAxis(.hidden)
        // 🎯 2. Ensure the legend is explicitly shown at the bottom
        .chartLegend(position: .bottom, alignment: .center)
        .chartYAxis {
            AxisMarks(values: .stride(by: 1)) { _ in
                AxisValueLabel()
            }
        }
    }

    private func oneRepMaxLineChart(for name: String) -> some View {
        let data = oneRepMaxData(for: name)
        
        return Chart {
            ForEach(data, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Weight", item.max)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.emerald500)
                
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Weight", item.max)
                )
                .foregroundStyle(.emerald500)
                // 🎯 Check if this is the last item in the array
                .annotation(position: .top, spacing: 8) {
                    if item.date == data.last?.date {
                        Text("\(item.max, specifier: "%.1f")")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 150)
        // Add extra padding so the label doesn't get cut off at the top
        .chartYScale(range: .plotDimension(padding: 20))
    }
    
    // MARK: - Helper View Components
    
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statSummaryCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    
    
    private var topExerciseFrequencyData: [(name: String, count: Int)] {
        // 1. Group the exercises
        let counts = Dictionary(grouping: allExercises, by: { $0.getSourceWorkout().name})
        
        // 2. Transform and Sort
        let sortedData = counts.map { (name: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count != $1.count {
                    return $0.count > $1.count // 🎯 Primary: Highest count first
                } else {
                    return $0.name < $1.name    // 🎯 Secondary: Alphabetical (Stable Tie-breaker)
                }
            }
        
        return Array(sortedData.prefix(6))
    }


    private func oneRepMaxData(for name: String) -> [(date: Date, max: Double)] {
        let filtered = allExercises.filter { $0.getSourceWorkout().name == name }
        
        return filtered.compactMap { exercise in
            // Get the best set from this specific exercise session
            let best1RM = exercise.sets.map { Double($0.weight) * (1.0 + Double($0.reps) / 30.0) }.max()
            return best1RM != nil ? (date: exercise.date, max: best1RM!) : nil
        }.sorted { $0.date < $1.date }
    }

    private var totalVolume: Double {
        allExercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { $0 + (Double($1.weight) * Double($1.reps)) }
        }
    }
}

#Preview {
    StatsView(allWorkoutOptions: [WorkoutOption(name: "Chest", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)])
}
