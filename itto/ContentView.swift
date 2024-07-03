//  ContentView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import SwiftUI
import CoreData
import Foundation
import UserNotifications
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var exams: FetchedResults<Exams>
    @FetchRequest(sortDescriptors: []) var projects: FetchedResults<Projects>
    @State private var selectedAccentColor: Color = Color.white
    @State private var intervalNumber = 4
    @State private var intervalTime = 30 // Interval time in minutes
    @State private var breakTime = 5 // Break time in minutes
    @State private var timer: Timer?
    @State private var countdownTime = 0
    @State private var timerIsPaused = true
    @State private var onBreak = false
    @State private var currentInterval = 1 // Track the current interval
    @State private var totalWorkTime = 0 // Total work time in seconds
    @State private var timerEndDate: Date?
    @State private var timerStartDate: Date?
    @State private var chosenSubject: String?
    @State private var timerStarted = false
    @State private var navigateToReportView = false
    @State private var selectedTopic = ""
    @State private var showDescSheet = false
    @State private var reportDescription = ""
    @State private var showAddSubjectsView = false
    @State private var isSavingReport = false
    
    private func filteredSubjects() -> [String] {
        let subjectNames = Set(subjects.compactMap { $0.name })
        let projectNames = Set(projects.compactMap { $0.name })
        return Array(subjectNames.union(projectNames))
    }
    let sets = [1, 2, 3, 4, 5, 6]
    let times = [1, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breakTimes = [1, 5, 10, 15, 20]
    
    init() {
        requestNotificationPermissions()
        
        func requestNotificationPermissions() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    // Notification permissions granted
                } else if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color(red: 1/255, green: 28/255, blue: 40/255)
                               .ignoresSafeArea()

            VStack {
                if(!timerStarted){
                    HStack{
                        VStack {
                            Text(LocalizedStringKey("Sets"))
                            Picker(LocalizedStringKey("Sets"), selection: $intervalNumber) {
                                ForEach(sets, id: \.self) { number in
                                    Text("\(number)")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 100)
                            .clipped()
                        }
                        VStack {
                            Text(LocalizedStringKey("Break"))
                            Picker(LocalizedStringKey("Break"), selection: $breakTime) {
                                ForEach(breakTimes, id: \.self) { number in
                                    Text("\(number) min")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 100)
                            .clipped()
                        }
                    }
                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), removal: .opacity.combined(with: .slide)))
                }
                
                CircularProgressView(progress: progressValue(), currentInterval: currentInterval, intervalNumber: intervalNumber, content: (!timerStarted && timerIsPaused) ? AnyView(intervalPicker) : AnyView(countdownView), isTimerStarted: timerStarted, accentColor: selectedAccentColor, onBreak: onBreak)
                
                    .padding()
                    .padding()
                
                
                if(!timerStarted){
                    HStack{
                        Picker(LocalizedStringKey("Subject"), selection: $chosenSubject) {
                            Text(LocalizedStringKey("Choose")).tag(nil as String?) // Handling nil
                            ForEach(filteredSubjects(), id: \.self) { name in
                                Text(name).tag(name as String?) // Ensure tags match the type of chosenSubject
                            }
                        }
                        .onChange(of: chosenSubject) {oldValue, newValue in
                            if !timerStarted {
                                self.selectedAccentColor = getColorForSelectedSubject()
                            }
                        }
                        
                        
                    } .padding()
                }
                
                HStack{
                    if timerIsPaused && timerStarted {
                        Button(action: {
                            resumeTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                        }
                        
                    }
                    
                    if(!timerIsPaused){
                        Button(action: {
                            pauseTimer()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                        }
                    }
                    
                    if timerIsPaused && !timerStarted {
                        Button(action: {
                            startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                        }
                    } else {
                        Button(action: {
                            stopTimer()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                                .padding()
                        }
                    }
                }
            }
            .onAppear {
                if let firstSubject = filteredSubjects().first {
                    self.chosenSubject = firstSubject
                }
            }
        }
        }
        .animation(.easeInOut, value: timerStarted)
        
        .sheet(isPresented: $showDescSheet) {
            descriptionSheet
            
        }
        .sheet(isPresented: $showAddSubjectsView) {
            AddSubjectView()
        }
        .onAppear {
            //printReportsData()
            // Resume timer when the app appears
            resumeTimerIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Update circular view when the app enters the foreground
            updateCircularView()
            // Resume timer if needed
            resumeTimerIfNeeded()
        }
    }
//    private func printReportsData() {
//        do {
//            let reports = try moc.fetch(Report.fetchRequest()) as [Report]
//            print("Reports Data:")
//            for report in reports {
//                print("Date: \(report.date ?? Date()), Subject: \(report.subjectName ?? "Unknown"), Total Time: \(report.totalTime) seconds, Description: \(report.desc ?? "No description")")
//            }
//        } catch {
//            print("Error fetching Reports: \(error)")
//        }
//    }
    private func resumeTimerIfNeeded() {
        // Resume timer only if it was running and paused
        if !timerStarted && !timerIsPaused {
            resumeTimer()
        }
    }
    var isExamAndClass: Bool {
        // Check if the chosenSubject exists in both Subjects and Exams
        let subjectExists = subjects.contains(where: { $0.name == chosenSubject })
        let examExists = exams.contains(where: { $0.name == chosenSubject })
        
        return subjectExists && examExists
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                // print("Notification permissions granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("timer_notification_title", comment: "Timer Notification")
        content.body = NSLocalizedString(message, comment: "Notification message")
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }



    private var descriptionSheet: some View {
        VStack {
            Text(LocalizedStringKey("What?"))
                .font(.largeTitle)
                .padding()
            
            TextField(LocalizedStringKey("Description"), text: $reportDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .padding()
            
            if isExamAndClass {
                Picker(LocalizedStringKey("Topics"), selection: $selectedTopic) {
                    Text(LocalizedStringKey("select_topic")).tag("")
                    if let chosenExam = exams.first(where: { $0.name == chosenSubject }) {
                        ForEach(chosenExam.topicsArray, id: \.self) { item in
                            Text(item)
                        }
                    }
                }
                .frame(width: 200, height: 100)
                .clipped()
                .padding()
            }
            Button(LocalizedStringKey("Save")) {
                let newReport = Report(context: moc)
                newReport.date = timerStartDate
                newReport.subjectName = chosenSubject
                newReport.totalTime = Int16(totalWorkTime)
                
                if isExamAndClass {
                    // If the selected subject is an exam and selectedTopic is not empty, use selectedTopic
                    newReport.desc = !reportDescription.isEmpty ? reportDescription : selectedTopic
                } else {
                    // If not, use reportDescription
                    newReport.desc = reportDescription
                }
                reportDescription = ""
            
                if moc.hasChanges {
                    do {
                        try moc.save()
                    } catch {
                        print("Could not save data: \(error.localizedDescription)")
                    }
                }
                showDescSheet = false
            }
            .padding()
            .cornerRadius(10)
        }
    }
    
    private func getColorForSelectedSubject() -> Color {
        if let subject = subjects.first(where: { $0.name == chosenSubject }) {
            return subject.color?.toColor() ?? Color.white
        } else if let project = projects.first(where: { $0.name == chosenSubject }) {
            return project.color?.toColor() ?? Color.white
        } else {
            return Color.white
        }
    }
    
    private var intervalPicker: some View {
        Picker(LocalizedStringKey("interval_time"), selection: $intervalTime) {
            ForEach(times, id: \.self) { number in
                Text("\(number)")
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(width: 100, height: 100)
        .clipped()
    }
    
    private var countdownView: some View {
        Text(timeString(time: countdownTime))
            .font(.largeTitle)
    }
    
    private func progressValue() -> CGFloat {
        let totalDuration = onBreak ? breakTime * 60 : intervalTime * 60
        return totalDuration > 0 ? CGFloat(countdownTime) / CGFloat(totalDuration) : 0
    }
    private func startTimer() {
        timerStartDate = Date()
        timer?.invalidate()
        currentInterval = 1
        onBreak = false
        countdownTime = intervalTime * 60
        timerIsPaused = false
        timerStarted = true
        totalWorkTime = 0
        
        // Configure the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateTimer()
        }
    }
    
    private func updateTimer() {
        if countdownTime > 0 {
            countdownTime -= 1
            if !onBreak {
                totalWorkTime += 1
            }
        } else {
            if onBreak {
                currentInterval += 1
                if currentInterval <= intervalNumber {
                    onBreak = false
                    countdownTime = intervalTime * 60
                    // Schedule a notification for the start of the next interval
                    scheduleNotification(message: "Starting next interval!")
                } else {
                    // If all intervals are completed, end the timer
                    stopTimer()
                    scheduleNotification(message: "The timer is over!") // Notification for timer completion
                }
            } else {
                // If it was an interval, start the break
                onBreak = true
                countdownTime = breakTime * 60
                // Schedule a notification for the start of the break
                scheduleNotification(message: "Time for a break!")
            }
        }
    }

    
    private func stopTimer() {
        timerEndDate = Date()
        timer?.invalidate()
        countdownTime = 0
        timerIsPaused = true
        timerStarted = false
        showDescSheet = true
    }
    private func updateCircularView() {
        if let startDate = timerStartDate {
            let elapsedTime = Int(Date().timeIntervalSince(startDate))
            var remainingTime: Int
            
            if onBreak {
                let breakStartTime = (currentInterval - 1) * (intervalTime * 60) // Only consider work interval times
                let breakElapsedTime = elapsedTime - breakStartTime
                remainingTime = max(breakTime * 60 - breakElapsedTime, 0)
            } else {
                let workElapsedTime = elapsedTime - (currentInterval - 1) * (intervalTime * 60 + breakTime * 60)
                let workDuration = intervalTime * 60
                remainingTime = max(workDuration - workElapsedTime, 0)
            }
            
            countdownTime = remainingTime
            totalWorkTime = elapsedTime
            
            if remainingTime == 0 {
                if onBreak {
                    // Schedule notification for the end of the break
                    scheduleNotification(message: "end_break_message")
                    // If there are more intervals,x start the next interval
                    if currentInterval < intervalNumber {
                        onBreak.toggle()
                        countdownTime = intervalTime * 60
                        currentInterval += 1
                    } else {
                        // If all intervals are finished, schedule notification for the end of the whole countdown
                        scheduleNotification(message: "finish_message")
                    }
                } else {
                    // If it's the end of the work interval, schedule notification for the start of the break
                    scheduleNotification(message: "break_message")
                }
            }
        }
    }
    
    
    
    
    private func pauseTimer() {
        timer?.invalidate()
        timerIsPaused = true
    }
    
    private func resumeTimer() {
        timerIsPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.countdownTime > 0 {
                self.countdownTime -= 1
                if !self.onBreak {
                    self.totalWorkTime += 1
                }
            } else {
                if self.currentInterval < self.intervalNumber {
                    self.onBreak.toggle()
                    self.countdownTime = self.onBreak ? self.breakTime * 60 : self.intervalTime * 60
                    if !self.onBreak {
                        self.currentInterval += 1
                    }
                } else {
                    self.timer?.invalidate()
                    
                }
            }
        }
    }
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    
}

struct CircularProgressView<Content: View>: View {
    var progress: CGFloat
    var currentInterval: Int
    var intervalNumber: Int
    var content: Content
    var isTimerStarted: Bool
    var accentColor: Color
    var onBreak: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 30)
                .opacity(0.1)
                .foregroundColor(Color.gray)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round))
            
                .foregroundColor(accentColor.opacity(onBreak ? 0.5 : 1))
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
            
            content
            if isTimerStarted{
                Text("\(currentInterval) / \(intervalNumber)")
                    .offset(y: -40)
            }
        }
        .frame(width: 200, height: 200)
    }
}
struct TopicPickerItem: View {
    var text: String
    var isSelected: Bool
    
    var body: some View {
        Text(text)
            .foregroundColor(isSelected ? .gray : .black)
    }
}



extension String {
    func toColor() -> Color {
        let rgbValues = self.split(separator: ",")
            .map { $0.split(separator: ":").last }
            .compactMap { $0 }
            .map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
        
        if rgbValues.count == 3 {
            return Color(red: rgbValues[0] / 255, green: rgbValues[1] / 255, blue: rgbValues[2] / 255)
        } else {
            return Color.white // Default color in case of parsing failure
        }
    }
}
