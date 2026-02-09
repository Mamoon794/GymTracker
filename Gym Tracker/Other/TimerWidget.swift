import WidgetKit
import SwiftUI
import ActivityKit

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // LOCK SCREEN VIEW
            HStack {
                Text("Rest Timer")
                    .font(.headline)
                Spacer()
                // This Text(timerInterval:...) counts down automatically!
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding()
            
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED VIEW (When you long press the island)
                DynamicIslandExpandedRegion(.leading) {
                    Label("Rest", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Optional: Add buttons here using AppIntents if you want interactive widgets
                    Text("Recover for next set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
            } compactLeading: {
                // COMPACT VIEW (Small pill left)
                Image(systemName: "timer")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                // COMPACT VIEW (Small pill right)
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 40)
            } minimal: {
                // MINIMAL VIEW (When multiple apps use the island)
                Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.caption2)
            }
        }
        
    }
        
}
