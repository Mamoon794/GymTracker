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
    @Query(sort: \WorkoutStat.workoutName, order: .reverse)
    private var allStats: [WorkoutStat]
    @AppStorage("lastSelectedWorkout") private var selectedWorkoutName: String = "Bench Press"
    @Environment(\.modelContext) var modelContext
    @State private var showSelectionSheet = false
    let allWorkouts: [WorkoutOption]
    
    private var selectedStat: WorkoutStat? {
        let option = allWorkouts.first(where: { $0.name == selectedWorkoutName })
        return option?.stats
    }
    
    private var topFrequencyData: [WorkoutStat] {
        Array(allStats.sorted { $0.frequency > $1.frequency }.prefix(7))
    }
    
    
    private var totalVolumeGlobal: Double {
        allStats.reduce(0) { $0 + $1.totalVolume }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Exercise Frequency Chart
                    chartCard(title: "Most Frequent Exercises") {
                        exerciseFrequencyChart()
                    }
                   
                    // 2. One Rep Max Progress
                    chartCard(title: "One Rep Max Progress") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Button {
                                showSelectionSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedWorkoutName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            

                            // Pass the specific stat object to the chart
                            if let stat = selectedStat {
                                oneRepMaxLineChart(stat: stat)
                            } else {
                                Text("No data available")
                                    .foregroundStyle(.secondary)
                                    .frame(height: 150)
                            }
                        }
                    }
                   
                    // 3. Quick Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        statSummaryCard(
                            label: "Exercises Tracked",
                            value: "\(allStats.reduce(0) { $0 + $1.totalExercises })",
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Total Days",
                            value: "\(calculateTotalDays())",
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Total Volume (kg)",
                            value: String(format: "%.0f", totalVolumeGlobal),
                            color: .emerald500
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                print("Updating")
                Task{
                    if (allStats == []){
                        for workout in allWorkouts{
                            let newStat = WorkoutStat(workout: workout)
                            modelContext.insert(newStat)
                        }
                    }
                    
                    else{
                        for stats in allStats{
                            stats.updateData()
                        }
                    }
                    try? modelContext.save()
                }
                
            }
            .sheet(isPresented: $showSelectionSheet) {
                NavigationStack {
                    WorkoutSelectionView(selectedOption: $selectedWorkoutName)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
   
    // MARK: - Chart Functions
   
    private func exerciseFrequencyChart() -> some View {
        
        Chart(topFrequencyData, id: \.workoutName) { stat in
            BarMark(
                x: .value("Count", stat.frequency),
                y: .value("Exercise", stat.workoutName)
            )
            .foregroundStyle(by: .value("Exercise", stat.workoutName))
            .cornerRadius(4)
            .annotation(position: .trailing) {
                Text("\(stat.frequency)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 240)
        .chartXAxis(.hidden)
        .chartLegend(position: .bottom, alignment: .center)
    }

    private func oneRepMaxLineChart(stat: WorkoutStat) -> some View {
        
        let data = stat.oneRepMaxHistory
        
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
                .annotation(position: .top, spacing: 8) {
                    // Only show label for the last/current max
                    if item.date == data.last?.date {
                        Text("\(item.max, specifier: "%.1f")")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 150)
        .chartYScale(range: .plotDimension(padding: 20))
    }
   
    // MARK: - Helper View Components (Unchanged)
   
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
    
    func calculateTotalDays() -> Int {
        var allDates: [Date] = []

        
        for stat in allStats {
            let exercises = stat.sourceWorkout.getExercises()
            
            let dates = exercises.map { $0.date }
            allDates.append(contentsOf: dates)
        }

        let uniqueDays = Set(allDates.map { Calendar.current.startOfDay(for: $0) })

        return uniqueDays.count
    }
}

//#Preview {
//    StatsView(allWorkoutOptions: [WorkoutOption(name: "Chest", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)])
//}
