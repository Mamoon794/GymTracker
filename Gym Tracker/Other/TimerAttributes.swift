import ActivityKit
import SwiftUI

struct TimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates (the timer)
        var endTime: Date
    }
    
    // Static data (doesn't change)
    var timerName: String
}