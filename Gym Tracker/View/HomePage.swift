//
//  HomePage.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import Charts
import SwiftData

extension Color {
      static let emerald400 = Color(red: 0.06, green: 0.78, blue: 0.53) // example values
      static let emerald500 = Color(red: 0.00, green: 0.70, blue: 0.50)
      static let slate400   = Color(red: 0.56, green: 0.60, blue: 0.67)
      static let slate800   = Color(red: 0.12, green: 0.14, blue: 0.18)
      static let slate300   = Color(red: 0.69, green: 0.73, blue: 0.78)
  }

enum Tab{
    case workout, history, stats, body
}

struct HomePage: View {
    @State private var activeTab: Tab = .workout
    @State private var showingAddWorkout = false
    @Query(sort: \Exercise.name) private var storedExercises: [Exercise]
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                VStack{
                    //Header
                    HStack{
                        VStack(alignment: .leading) {
                            Text("FitFlux")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(colors: [.emerald400, .blue], startPoint: .leading, endPoint: .trailing)
                                )
                            Text(Date.now, style: .date)
                                .font(.caption)
                                .foregroundColor(.slate400)
                        }
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.slate300)
                                .padding(10)
                                .background(Color.slate800)
                                .clipShape(Circle())
                        }
                    }.padding()
                    //Current Sessions
                    
                        VStack {
                            switch activeTab {
                            case .workout:
                                WorkoutView(exercises: storedExercises)
                            case .history:
                                CalendarView()
                            case .stats:
                                StatsView()
                            case .body:
                                BodyTrackerView()
                            }
                        }
                        .padding(.bottom, 100) // Space for bottom nav
                    
                    //Exercises
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: openNewWorkout) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.emerald500)
                                .clipShape(Circle())
                                .shadow(color: .emerald500.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 90) // Position above tab bar
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            NewWorkout()
        }
    }
    
    private func openNewWorkout() {
        showingAddWorkout = true
    }
}

#Preview {
    HomePage()
}
