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
    @State private var isBarHidden: Bool = false
    
    
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
                                WorkoutView()
                                    .id("workout")
                            case .history:
                                CalendarView(isBarHidden: $isBarHidden)
                            case .stats:
                                StatsView()
                            }
                        }
                        .padding(.bottom, isBarHidden ? 10 : 100) // Space for bottom nav
                        .background(isBarHidden ? Color.clear : Color(.systemGroupedBackground))
                    
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
                    // 🎯 The Container (Invisible Hit Box)
                    ZStack {
                        Color.clear // Detects touches in the empty space
                        
                        Capsule()
                            .fill(Color.emerald500)
                            .frame(width: 6, height: 60)
                    }
                    .frame(width: 44, height: 100)
                    .contentShape(Rectangle())
                    .padding(.trailing, 0)
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .onTapGesture {
                        showBar()
                    }
                    .gesture(
                        DragGesture().onEnded { value in
                            if value.translation.width < -15 {
                                showBar()
                            }
                        }
                    )
                }
                
            }
            
        }
        .sheet(isPresented: $showingAddWorkout) {
            NewWorkout()
        }
        
    }
    
    private func showBar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isBarHidden = false
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
            .offset(y: isBarHidden ? 100 : 0)
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
            NavigationLink(destination: PersonCustomization()) {
                Image(systemName: "person.fill")
                    .foregroundColor(.slate300)
                    .padding(10)
                    .background(Color.slate800)
                    .clipShape(Circle())
            }
        }.padding(.horizontal, 10)
    }
    
    private func bottomNavBar() -> some View {
        VStack(spacing: 0) {
            ZStack {
                Color.clear // Makes the whole area tappable
                Capsule()
                    .frame(width: 40, height: 4)
                    .foregroundStyle(Color.slate400)
            }
            .frame(height: 30) // 🎯 Large hit area (30px vs 4px)
            .contentShape(Rectangle()) // Ensures the clear area detects touchzz
            .onTapGesture { hideBar() }
            .gesture(
                DragGesture().onEnded { value in
                    if value.translation.height > 15 { hideBar() }
                }
            )
            HStack{
                navItem(label: "Calendar", icon: "calendar", tab: .history)
                navItem(label: "Workout", icon: "dumbbell.fill", tab: .workout)
                navItem(label: "Stats", icon: "chart.bar.fill", tab: .stats)
            }
            
            
        }
        
        .padding(.bottom, 30) // Extra padding for home indicator
        .background(Color.slate800.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 20 { // If dragged down
                        withAnimation(.spring()) {
                            isBarHidden = true
                        }
                    }
                }
        )
        .offset(y: isBarHidden ? 200 : 0)
    }
    
    private func hideBar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isBarHidden = true
        }
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
    
}


#Preview {
    HomePage()
}

