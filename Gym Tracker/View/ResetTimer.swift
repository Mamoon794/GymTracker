import SwiftUI
import ActivityKit
import UserNotifications
import AudioToolbox

@Observable
class RestTimerManager {
    var timeRemaining: TimeInterval = 0
    var isActive = false
    var totalTime: TimeInterval = 0
    private var activity: Activity<TimerAttributes>?
    var currentExerciseName: String = "Exercise"
    
    private var timer: Timer?
    private var endTime: Date? // Used to track time even when app is backgrounded

    var showTimerAlert = false
    
    init() {
        // Request notification permission once on startup
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func start(seconds: TimeInterval, exerciseName: String) {
        // 1. Set State
        self.showTimerAlert = false
        self.currentExerciseName = exerciseName
        totalTime = seconds
        timeRemaining = seconds
        isActive = true
        endTime = Date().addingTimeInterval(seconds)
        print("HERE")
        startLiveActivity(endTime: endTime!)
        
        // 2. Schedule Local Notification (Background Alert)
        scheduleNotification(seconds: seconds)
        
        // 3. Start In-App Timer
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
        endTime = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        endLiveActivity()
    }
    
    func addTime(_ seconds: TimeInterval) {
         guard let currentEnd = endTime else { 
            start(seconds: seconds, exerciseName: self.currentExerciseName)
            return 
        }
        let newEnd = currentEnd.addingTimeInterval(seconds)
        endTime = newEnd
        totalTime += seconds // Update total for progress bar calculations

        if let newEnd = endTime {
            updateLiveActivity(newEnd: newEnd)
        }
        
        // Reschedule notification
        let newRemaining = newEnd.timeIntervalSinceNow
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduleNotification(seconds: newRemaining)
    }
    
    private func tick() {
        guard let endTime = endTime else { return }
        let remaining = endTime.timeIntervalSinceNow
        
        if remaining <= 0 {
            finishTimer()
        } else {
            timeRemaining = remaining
        }
    }
    
    private func finishTimer() {
        stop();
        showTimerAlert = true
        AudioServicesPlaySystemSound(SystemSoundID(1005)) 
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    }

    private func scheduleNotification(seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "\(self.currentExerciseName) Rest Complete"
        content.body = "Time to start your next set!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "RestTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }

    private func startLiveActivity(endTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        
        Task {
            if let existingActivity = activity {
                await existingActivity.end(.init(state: .init(endTime: Date()), staleDate: nil), dismissalPolicy: .immediate)
            }
            
            let attributes = TimerAttributes(timerName: self.currentExerciseName)
            let state = TimerAttributes.ContentState(endTime: endTime)
            
            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
                print("✅ Live Activity started successfully")
            } catch {
                print("❌ Failed to start Live Activity: \(error)")
            }
        }
    }
    
    private func updateLiveActivity(newEnd: Date) {
        Task {
            let newState = TimerAttributes.ContentState(endTime: newEnd)
            await activity?.update(.init(state: newState, staleDate: nil))
        }
    }
    
    private func endLiveActivity() {
        Task {
            // End immediately
            await activity?.end(.init(state: .init(endTime: Date()), staleDate: nil), dismissalPolicy: .immediate)
            activity = nil
        }
    }
}




struct RestTimerOverlay: View {
    @Bindable var manager: RestTimerManager
    
    var body: some View {
        if manager.isActive {
            HStack {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.timeRemaining / manager.totalTime))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: manager.timeRemaining)
                }
                .frame(width: 30, height: 30)
                
                // Text Time
                Text(formatTime(manager.timeRemaining))
                    .font(.headline)
                    .monospacedDigit() // Prevents jittering
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Controls
                Button("+30s") { manager.addTime(30) }
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)

                Button(action: { manager.stop() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
            .background(Color.blue) // Or your app's theme color
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func formatTime(_ totalSeconds: TimeInterval) -> String {
        let seconds = Int(totalSeconds)
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

