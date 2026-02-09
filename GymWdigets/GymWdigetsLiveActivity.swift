//
//  GymWdigetsLiveActivity.swift
//  GymWdigets
//
//  Created by Mamoon Akhtar on 2026-02-09.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GymWdigetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GymWdigetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymWdigetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension GymWdigetsAttributes {
    fileprivate static var preview: GymWdigetsAttributes {
        GymWdigetsAttributes(name: "World")
    }
}

extension GymWdigetsAttributes.ContentState {
    fileprivate static var smiley: GymWdigetsAttributes.ContentState {
        GymWdigetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GymWdigetsAttributes.ContentState {
         GymWdigetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GymWdigetsAttributes.preview) {
   GymWdigetsLiveActivity()
} contentStates: {
    GymWdigetsAttributes.ContentState.smiley
    GymWdigetsAttributes.ContentState.starEyes
}
