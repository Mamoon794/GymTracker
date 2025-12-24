//
//  StatsView.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import Charts

struct StatsView: View {
    // Sample data - in a real app, this would come from your database
    @State private var exerciseData = [
        (name: "Bench Press", count: 12),
        (name: "Squat", count: 8),
        (name: "Deadlift", count: 5),
        (name: "Overhead Press", count: 7)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Exercise Breakdown Chart
                    chartCard(title: "Exercise Frequency") {
                        exerciseFrequencyChart()
                    }
                    
                    // 2. One Rep Max Progress
                    chartCard(title: "One Rep Max: Bench Press") {
                        oneRepMaxLineChart()
                    }
                    
                    // 3. Quick Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        statSummaryCard(label: "Total Workouts", value: "24", color: .blue)
                        statSummaryCard(label: "Volume (kg)", value: "12,450", color: .green)
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
        Chart(exerciseData, id: \.name) { item in
            BarMark(
                x: .value("Count", item.count),
                y: .value("Exercise", item.name)
            )
            .foregroundStyle(by: .value("Exercise", item.name))
        }
        .frame(height: 200)
    }
    
    private func oneRepMaxLineChart() -> some View {
        // Mock progress data
        let progress = [100, 102.5, 102.5, 105, 110]
        
        return Chart {
            ForEach(Array(progress.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Week", index + 1),
                    y: .value("Weight", value)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Week", index + 1),
                    y: .value("Weight", value)
                )
            }
        }
        .frame(height: 150)
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
}

#Preview {
    StatsView()
}
