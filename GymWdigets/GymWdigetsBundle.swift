//
//  GymWdigetsBundle.swift
//  GymWdigets
//
//  Created by Mamoon Akhtar on 2026-02-09.
//

import WidgetKit
import SwiftUI

@main
struct GymWdigetsBundle: WidgetBundle {
    var body: some Widget {
        GymWdigets()
//        GymWdigetsControl()
        
        TimerActivityWidget()
    }
}
