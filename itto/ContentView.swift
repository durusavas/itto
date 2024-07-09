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
    @FetchRequest(
        entity: DailySubjects.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \DailySubjects.date, ascending: true)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.startOfDay(for: Date()) as CVarArg)
    ) var dailySubjects: FetchedResults<DailySubjects>
    
    
    
    @State private var selectedAccentColor: Color = Color.white
    @State private var intervalNumber = 4
    @State private var intervalTime = 30 // Interval time in minutes
    @State private var breakTime = 5 // Break time in minutes
    @State private var timer: Timer?
    @State private var countdownTime = 0
    @State private var timerIsPaused = true
    @State private var onBreak = false
    @State private var currentInterval = 1
    @State private var totalWorkTime = 0
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
        NavigationStack {
            
            
            
            VStack {
                if !timerStarted {
                    
                    
                    VStack{
                        HStack {
                            VStack {
                                Text(LocalizedStringKey("Sets"))
                                //  .foregroundColor(Color.accentColor1)
                                Picker(LocalizedStringKey("Sets"), selection: $intervalNumber) {
                                    ForEach(sets, id: \.self) { number in
                                        Text("\(number)")
                                        
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 70, height: 100)
                                .clipped()
                                .padding()
                                .background(Color(red: 15/255, green: 20/255, blue: 33/255))
                                .cornerRadius(100)
                            }
                            VStack{
                                Text(LocalizedStringKey("Interval"))
                                // .foregroundColor(Color.accentColor1)
                                
                                Picker(LocalizedStringKey("Interval"), selection: $intervalTime) {
                                    ForEach(times, id: \.self) { number in
                                        Text("\(number)")
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 70, height: 100)
                                .clipped()
                                .padding()
                                .background(Color(red: 15/255, green: 20/255, blue: 33/255))
                                .cornerRadius(100)
                                
                                
                                
                            }
                            
                            
                            
                            VStack {
                                Text(LocalizedStringKey("Break"))
                                // .foregroundColor(Color.accentColor1)
                                Picker(LocalizedStringKey("Break"), selection: $breakTime) {
                                    ForEach(breakTimes, id: \.self) { number in
                                        Text("\(number)")
                                        
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 70, height: 100)
                                .clipped()
                                .padding()
                                .background(Color(red: 15/255, green: 20/255, blue: 33/255))
                                .cornerRadius(100)
                            }
                        }
                        
                        
                    }
                    .padding(30)
                    MainCircleView(colors: getDailySubjectColors(for: Date())) {
                        Button(action: {
                            startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                        }
                    }
                    .padding()
                    .padding()
                    
                    
                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), removal: .opacity.combined(with: .slide)))
                }
                
                if timerStarted{
                    CircularProgressView(
                        progress: progressValue(),
                        currentInterval: currentInterval,
                        intervalNumber: intervalNumber,
                        content: AnyView(timerStarted ? countdownView as! Text : Text("")),
                        isTimerStarted: timerStarted,
                        accentColor: selectedAccentColor,
                        onBreak: onBreak
                    )
                    .padding()
                    .padding()
                    
                    
                }
                if !timerStarted {
                    HStack {
                        Picker(LocalizedStringKey("Subject"), selection: $chosenSubject) {
                            Text(LocalizedStringKey("Choose")).tag(nil as String?) // Handling nil
                                .foregroundColor(Color.accentColor1)
                            ForEach(filteredSubjects(), id: \.self) { name in
                                Text(name).tag(name as String?)
                                    .foregroundColor(Color.accentColor1)
                            }
                        }
                        .onChange(of: chosenSubject) { oldValue, newValue in
                            if !timerStarted {
                                self.selectedAccentColor = getColorForSelectedSubject()
                            }
                        }
                    }
                    .padding()
                }
                
                HStack {
                    if timerIsPaused && timerStarted {
                        Button(action: {
                            resumeTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.accentColor1)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                        }
                    }
                    
                    if !timerIsPaused {
                        Button(action: {
                            pauseTimer()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(100)
                                .foregroundColor(Color.accentColor1)
                        }
                    }
                    
                    if !timerIsPaused && timerStarted {
                        Button(action: {
                            stopTimer()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.accentColor1)
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
        .animation(.easeInOut, value: timerStarted)
        .sheet(isPresented: $showDescSheet) {
            descriptionSheet
        }
        .sheet(isPresented: $showAddSubjectsView) {
            AddSubjectView()
        }
        .onAppear {
            resumeTimerIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateCircularView()
            resumeTimerIfNeeded()
        }
    }
    
    private func resumeTimerIfNeeded() {
        if !timerStarted && !timerIsPaused {
            resumeTimer()
        }
    }
    
    var isExamAndClass: Bool {
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
    private func getDailySubjectColors(for date: Date) -> [Color] {
        let calendar = Calendar.current
        let filteredSubjects = dailySubjects.filter { calendar.isDate($0.date ?? Date(), inSameDayAs: date) }
        let colors = filteredSubjects.compactMap { $0.color?.toColor() }
        return colors.isEmpty ? [Color.gray, Color.blue] : colors // Fallback colors if no subjects found
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
                        .foregroundColor(Color.accentColor1)
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
                    newReport.desc = !reportDescription.isEmpty ? reportDescription : selectedTopic
                } else {
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
                    scheduleNotification(message: "Starting next interval!")
                } else {
                    stopTimer()
                    scheduleNotification(message: "The timer is over!")
                }
            } else {
                onBreak = true
                countdownTime = breakTime * 60
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
                let breakStartTime = (currentInterval - 1) * (intervalTime * 60)
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
                    scheduleNotification(message: "end_break_message")
                    if currentInterval < intervalNumber {
                        onBreak.toggle()
                        countdownTime = intervalTime * 60
                        currentInterval += 1
                    } else {
                        scheduleNotification(message: "finish_message")
                    }
                } else {
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

struct CircularGradientBackground: ViewModifier {
    var colors: [Color]
    
    func body(content: Content) -> some View {
        content
        
            .background(
                Circle()
                
                    .fill(LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
        
    }
}

extension View {
    func circularGradientBackground(colors: [Color]) -> some View {
        self.modifier(CircularGradientBackground(colors: colors))
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
            
            if isTimerStarted {
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
        let components = self.replacingOccurrences(of: " ", with: "").split(separator: ",").map { String($0) }
        let rgbValues = components.map { component -> CGFloat in
            let value = component.split(separator: ":")[1]
            return CGFloat(Double(value) ?? 0) / 255.0
        }
        return Color(red: rgbValues[0], green: rgbValues[1], blue: rgbValues[2])
    }
}
#Preview {
    ContentView()
}
