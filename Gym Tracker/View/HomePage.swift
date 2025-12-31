//
//  HomePage.swift
//  Gym Tracker
//
//  Created by Mamoon Akhtar on 2025-11-24.
//

import SwiftUI
import Charts
import SwiftData



enum Tab{
    case workout, history, stats
}

struct HomePage: View {
    @State private var activeTab: Tab = .workout
    @State private var showingAddWorkout = false
    @State private var showingPersonCustomization = false
    @State private var isBarHidden: Bool = false
    @Query private var workoutOptions: [WorkoutOption]
    
    static var todayStart: Date {
            Calendar.current.startOfDay(for: .now)
        }
        
    static var tomorrowStart: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
    }
    
    @Query(filter: #Predicate<Exercise> { exercise in
        exercise.date >= todayStart && exercise.date < tomorrowStart
    }, sort: \Exercise.date) private var storedExercises: [Exercise]
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                VStack{
                    //Header
                    if activeTab == .workout{
                        header()
                    }
                    //Current Sessions
                    
                        VStack {
                            switch activeTab {
                            case .workout:
                                WorkoutView(exercises: storedExercises, allWorkoutOptions: workoutOptions)
                            case .history:
                                CalendarView(isBarHidden: $isBarHidden, allWorkoutOptions: workoutOptions)
                            case .stats:
                                StatsView()
                            }
                        }
                        .padding(.bottom, 10) // Space for bottom nav
                    
                    //Exercises
                }
                
                VStack {
                    Spacer()
                    if activeTab == .workout {
                        fabButton
                    }
//                    fabButton
                              
                    bottomNavBar()
                }
                if isBarHidden {
                    Capsule()
                        .fill(Color.emerald500)
                        .frame(width: 60, height: 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture {
                            withAnimation(.spring()) { isBarHidden = false }
                        }
                        // Also supports swiping up to reveal
                        .gesture(
                            DragGesture().onEnded { value in
                                if value.translation.height < -20 {
                                    withAnimation(.spring()) { isBarHidden = false }
                                }
                            }
                        )
                }
                
            }
            
        }
        .sheet(isPresented: $showingAddWorkout) {
            NewWorkout()
        }
        .sheet(isPresented: $showingPersonCustomization) {
            PersonCustomization()
        }
        
    }
    
    private var fabButton: some View {
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
            .padding(.bottom, 90)
        }
    }
    
    private func header()-> some View{
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
            Button(action: openPersonCustomization) {
                Image(systemName: "person.fill")
                    .foregroundColor(.slate300)
                    .padding(10)
                    .background(Color.slate800)
                    .clipShape(Circle())
            }
        }.padding(.horizontal, 10)
    }
    
    private func bottomNavBar() -> some View {
        HStack(spacing: 0) {
            Capsule()
            .frame(width: 40, height: 4)
            .foregroundStyle(Color.slate400)
            .padding(.top, 8)
            navItem(label: "Calendar", icon: "calendar", tab: .history)
            navItem(label: "Workout", icon: "dumbbell.fill", tab: .workout)
            navItem(label: "Stats", icon: "chart.bar.fill", tab: .stats)
        }
        
        .padding(.top, 12)
        .padding(.bottom, 30) // Extra padding for home indicator
        .background(Color.slate800.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 { // If dragged down
                        withAnimation(.spring()) {
                            isBarHidden = true
                        }
                    }
                }
        )
        .offset(y: isBarHidden ? 200 : 0)
    }

    private func navItem(label: String, icon: String, tab: Tab) -> some View {
        Button(action: { activeTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(activeTab == tab ? .emerald400 : .slate400)
        }
    }
    
    
    
    private func openNewWorkout() {
        showingAddWorkout = true
    }
    
    private func openPersonCustomization(){
        showingPersonCustomization = true
    }
}


#Preview {
    HomePage()
}

