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
    @AppStorage("lastSelectedWorkoutWeight") private var selectedWorkoutWeight: String = "Bench Press"
    @Environment(\.modelContext) var modelContext
    @State private var showSelectionSheet = false
    @State private var showWeightSelectionSheet = false
    
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

    private var selectedWeightStat: WorkoutStat? {
        let option = allStats.first(where: { $0.sourceWorkout.name == selectedWorkoutWeight })
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
                    
                    chartCard(title: "Max Weight Progress") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Button {
                                showWeightSelectionSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedWorkoutWeight)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            

                            // Pass the specific stat object to the chart
                            if let stat = selectedWeightStat {
                                maxWeightLineChart(stat: stat)
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
             .sheet(isPresented: $showWeightSelectionSheet) {
                 NavigationStack {
                     WorkoutSelectionView(selectedOption: $selectedWorkoutWeight)
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
        let maxRMValue = stat.maxOneRepStat?.oneRepMaxValue ?? 0
        
        return NavigationLink(destination: DetailedProgressView(
            title: "1RM History: \(stat.workoutName)",
            data: data,
            prLabel: "Max 1RM",
            prValue: maxRMValue
        )) {
            // Mini Chart: Latest 8 only, Label on last only
            MetricLineChart(data: data, prLabel: "M 1R", prValue: maxRMValue, isDetailed: false)
                .frame(height: 150)
                // Disable hit testing on the chart itself so the NavLink handles the tap
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()) // Removes blue link color
    }

    private func maxWeightLineChart(stat: WorkoutStat) -> some View {
        let data = stat.maxWeightHistory
        let maxWeightValue = stat.maxWeightStat?.weightValue ?? 0
        
        return NavigationLink(destination: DetailedProgressView(
            title: "Max Weight History: \(stat.workoutName)",
            data: data,
            prLabel: "PR",
            prValue: maxWeightValue
        )) {
            // Mini Chart: Latest 8 only, Label on last only
            MetricLineChart(data: data, prLabel: "PR", prValue: maxWeightValue, isDetailed: false)
                .frame(height: 150)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
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



struct MetricLineChart: View {
    let data: [maxEntries]
    let prLabel: String?
    let prValue: Double?
    let isDetailed: Bool
    
    // 1. Prepare the data: Slice it for mini view, keep it full for detailed view
    private var displayData: [maxEntries] {
        let sorted = data.sorted { $0.date < $1.date }
        if isDetailed {
            return sorted
        } else {
            return Array(sorted.suffix(8)) // Only show latest 8 on dashboard
        }
    }
    
    var body: some View {
        Chart {
            ForEach(displayData, id: \.date) { item in
                // Draw the Line
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Weight", item.max)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.emerald500)
                
                // Draw the Points (Dots)
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Weight", item.max)
                )
                .foregroundStyle(.emerald500)
                // 2. The Logic: Conditionally show the text label
                .annotation(position: .top, spacing: 8) {
                    if shouldShowLabel(for: item) {
                        Text("\(item.max, specifier: "%.1f")")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(2)
                            .background(Color(.systemBackground).opacity(0.8))
                    }
                    
                }
            }
            
            // Draw PR Line (Only if it exists)
            if let pr = prValue, pr > 0 {
                RuleMark(y: .value(prLabel ?? "PR", pr))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5])) // Dashed line
                .foregroundStyle(.blue.opacity(0.5))
                
                .annotation(
                    position: isDetailed ? .top : .top,
                    alignment: isDetailed ? .trailing : .leading,
                    spacing: isDetailed ? 10 : 0
                ) {
                    Text("\(prLabel ?? "PR"): \(pr, specifier: "%.1f")")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .padding(4)
                        .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                        .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                        .shadow(color: Color(.systemBackground), radius: 1, x: 0, y: 0)
                        
                        // In Detailed View, move it completely outside/above the chart
                        // In Mini View, keep it tucked inside
                        .offset(y: isDetailed ? -20 : 0)
                }
            }
        }
        // Hide the legend generated by the symbols
        .chartLegend(.hidden)
        .chartYScale(range: .plotDimension(padding: 20))
    }
    
    // Helper function to keep the view body clean
    private func shouldShowLabel(for item: maxEntries) -> Bool {
        // Condition A: If it's the detailed view, show EVERYTHING.
        if isDetailed { return true }
        
        // Condition B: If it's the mini view, only show the LAST item.
        // Note: We compare dates because objects might be distinct copies
        return item.date == displayData.last?.date
    }
}

// The Destination View when you click the chart
struct DetailedProgressView: View {
    let title: String
    let data: [maxEntries]
    let prLabel: String?
    let prValue: Double?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                // Use geometry.size.width instead of UIScreen.main.bounds.width
                let dynamicWidth = max(geometry.size.width - 40, CGFloat(data.count * 50))
                
                VStack(alignment: .leading) {
                    MetricLineChart(data: data, prLabel: prLabel, prValue: prValue, isDetailed: true)
                        .frame(width: dynamicWidth, height: 300)
                        .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}


//#Preview {
//    StatsView(allWorkoutOptions: [WorkoutOption(name: "Chest", category: WorkoutCategory.chest, image: WorkoutCategory.chest.icon)])
//}

