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
    
    @Query(sort: [SortDescriptor(\MonthlyWorkout.year, order: .forward), SortDescriptor(\MonthlyWorkout.month, order: .forward)]) 
    private var monthlyWorkouts: [MonthlyWorkout]

    private var totalExercises: Int {
        allStats.reduce(0) { $0 + $1.totalExercises }
    }
    
    private var currentMonthSummary: MonthlyWorkout? {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return monthlyWorkouts.first(where: { $0.month == currentMonth && $0.year == currentYear })
    }

    private var totalDays: Int {
        return monthlyWorkouts.reduce(0) { $0 + $1.totalDays }
    }

    
    private var selectedStat: WorkoutStat? {
        let option = allStats.first(where: { $0.sourceWorkout.name == selectedWorkoutName })
        return option
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
                    NavigationLink(destination: FullFrequencyView(allStats: allStats)) {
                        chartCard(title: "Most Frequent Exercises") {
                            exerciseFrequencyChart()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                   
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
                            label: "Exercises Per Day",
                            value: String(format: "%.1f", Double(totalExercises)/Double(totalDays)),
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Days per Week",
                            value: String(format: "%.1f", calculateMonthlyFrequency()),
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Exercises Tracked",
                            value: "\(totalExercises)",
                            color: .blue
                        )
                        statSummaryCard(
                            label: "Total Days",
                            value: "\(totalDays)",
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
                Task{                    
                    for stats in allStats{
                        stats.updateData()
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
        .padding(.horizontal, 3)
    }

    private func oneRepMaxLineChart(stat: WorkoutStat) -> some View {
        
        let data = stat.oneRepMaxHistory

        let maxWeightValue = stat.maxWeightStat?.weightValue ?? 0
        
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
            
            if maxWeightValue > 0 {
                RuleMark(
                    y: .value("Max Weight", maxWeightValue)
                )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5])) // Dashed line
                .foregroundStyle(.blue.opacity(0.5))
                
                .annotation(position: .top, alignment: .leading) {
                    Text("PR: \(maxWeightValue, specifier: "%.0f")")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                                            .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                                            .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                        .padding(2)
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


    func calculateMonthlyFrequency() -> Double {
        let calendar = Calendar.current
        let now = Date.now
        

        guard let firstMonth = monthlyWorkouts.min(by: { 
            ($0.year, $0.month) < ($1.year, $1.month) 
        }) else {
            return 0.0 
        }
        
        // 2. Create a Date object for the 1st day of that starting month
        var components = DateComponents()
        components.year = firstMonth.year
        components.month = firstMonth.month
        components.day = 1
        
        // Fallback to 'now' if date creation fails (prevents crash)
        let startDate = calendar.date(from: components) ?? now
        
        // 3. Calculate Weeks Passed (Total Lifespan)
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: now).day ?? 1
        

        let weeksPassed = max(Double(daysSinceStart) / 7.0, 0.14)
        

        let totalUniqueDays = monthlyWorkouts.reduce(0) { total, summary in
            total + summary.totalDays
        }
        

        return Double(totalUniqueDays) / weeksPassed
    }
}



struct FullFrequencyView: View {
    var allStats: [WorkoutStat]
    
    // 1. Sort all data, remove 0s if you want
    var sortedStats: [WorkoutStat] {
        allStats
            .filter { $0.frequency > 0 } // Optional: Hide exercises never done
            .sorted { $0.frequency > $1.frequency }
    }
    
    // 2. Calculate height: 50pts per bar, but at least screen height so it looks full
    var chartHeight: CGFloat {
        let calculated = CGFloat(sortedStats.count * 50)
        return max(calculated, 400)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("All Exercises by Frequency")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
                
                Chart(sortedStats, id: \.workoutName) { stat in
                    BarMark(
                        x: .value("Count", stat.frequency),
                        y: .value("Exercise", stat.workoutName)
                    )
                    .foregroundStyle(by: .value("Exercise", stat.workoutName))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(stat.frequency)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                // 3. Apply the dynamic height here
                .frame(height: chartHeight)
                // 4. Optimization: Fix the X axis so it doesn't jump around
                .chartXAxis { AxisMarks(position: .top) }
                .chartLegend(.hidden) // Legend is redundant here
            }
            .padding()
        }
        .navigationTitle("Exercise Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}




//#Preview {
//    StatsView(allWorkoutOptions: [WorkoutOption(name: "Chest", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)])
//}

