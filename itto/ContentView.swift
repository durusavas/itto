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
    @State private var intervalTime = 30
    @State private var breakTime = 5
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
                } else if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var body: some View {
        ZStack{
            LinearGradient(
                gradient: Gradient(colors: [Color("bg2"), Color("bg1")]),
                startPoint: .center,
                endPoint: .topTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                if !timerStarted {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.gray.opacity(0.05))
                                .frame(width: 320, height: 150)
                            
                            HStack {
                                VStack {
                                    Text(LocalizedStringKey("Sets"))
                                        .font(.custom("Poppins-Regular", size: 17))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Picker(LocalizedStringKey("Sets"), selection: $intervalNumber) {
                                        ForEach(sets, id: \.self) { number in
                                            Text("\(number)")
                                                .font(.custom("Poppins-Regular", size: 17))
                                        }
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 120)
                                .clipped()
                                .padding()
                                .cornerRadius(50)
                                
                                VStack {
                                    Text(LocalizedStringKey("Interval"))
                                        .font(.custom("Poppins-Regular", size: 17))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Picker(LocalizedStringKey("Interval"), selection: $intervalTime) {
                                        ForEach(times, id: \.self) { number in
                                            Text("\(number)")
                                                .font(.custom("Poppins-Regular", size: 17))
                                        }
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 120)
                                .clipped()
                                .padding()
                                
                                VStack {
                                    Text(LocalizedStringKey("Break"))
                                        .font(.custom("Poppins-Regular", size: 17))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Picker(LocalizedStringKey("Break"), selection: $breakTime) {
                                        ForEach(breakTimes, id: \.self) { number in
                                            Text("\(number)")
                                                .font(.custom("Poppins-Regular", size: 17))
                                        }
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 120)
                                .clipped()
                                .padding()
                                .cornerRadius(50)
                            }
                        }
                        .padding()
                    }
                    
                    MainCircleView(colors: getDailySubjectColors(for: Date())) {
                        Button(action: {
                            startTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .padding()
                                .cornerRadius(100)
                                .opacity(0.8)
                         
                        }
                    }
                    .padding()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), removal: .opacity.combined(with: .slide)))
                   
                }
                
                if timerStarted {
                    CircularProgressView(
                        progress: progressValue(),
                        currentInterval: currentInterval,
                        intervalNumber: intervalNumber,
                        content: countdownView,
                        isTimerStarted: timerStarted,
                        actColor: selectedAccentColor,
                        onBreak: onBreak
                    )
                    
                    .padding()
                }
                
                if !timerStarted {
                    HStack {
                        Picker(LocalizedStringKey("Subject"), selection: $chosenSubject) {
                            Text(LocalizedStringKey("Choose")).tag(nil as String?)
                            ForEach(filteredSubjects(), id: \.self) { name in
                                Text(name).tag(name as String?)
                                    .font(.custom("Poppins-Regular", size: 17))
                            }
                        }
                        .onChange(of: chosenSubject) { oldValue, newValue in
                            if !timerStarted {
                                self.selectedAccentColor = getColorForSelectedSubject()
                            }
                        }
                    }
                    .padding()
                    Spacer()
                }
                
                HStack {
                    if timerIsPaused && timerStarted {
                        Button(action: {
                            resumeTimer()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                                .opacity(0.8)
                               
                             
                        }
                    }
                    
                    if !timerIsPaused {
                        Button(action: {
                            pauseTimer()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.largeTitle)
                                .padding()
                                .foregroundColor(.white)
                                .opacity(0.8)
                          
                            
                        }
                    }
                    
                    if !timerIsPaused && timerStarted {
                        Button(action: {
                            stopTimer()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.largeTitle)
                                .padding()
                                .foregroundColor(.white)
                                .opacity(0.8)
                               
                          
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
    private func updateCircularView() {
        if !timerIsPaused{
            guard let startDate = timerStartDate else { return }
            
            let elapsedTime = Int(Date().timeIntervalSince(startDate))
            _ = intervalNumber * (intervalTime * 60 + breakTime * 60)
            let completedIntervals = elapsedTime / (intervalTime * 60 + breakTime * 60)
            let timeInCurrentInterval = elapsedTime % (intervalTime * 60 + breakTime * 60)
            
            if completedIntervals >= intervalNumber {
                stopTimer()
            } else {
                currentInterval = completedIntervals + 1
                if timeInCurrentInterval < intervalTime * 60 {
                    onBreak = false
                    countdownTime = intervalTime * 60 - timeInCurrentInterval
                } else {
                    onBreak = true
                    countdownTime = (breakTime * 60) - (timeInCurrentInterval - intervalTime * 60)
                }
            }
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
        ZStack {
            Color.bg2
                .ignoresSafeArea()
            
            VStack {
                Text(LocalizedStringKey("What?"))
                    .font(.custom("Poppins-SemiBold", size: 25))
                    .padding()
                
                TextField(LocalizedStringKey("Description"), text: $reportDescription)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .font(.custom("Poppins-Regular", size: 16))
                
                if let chosenSubject = chosenSubject {
                    Picker(LocalizedStringKey("Topics"), selection: $selectedTopic) {
                        Text(LocalizedStringKey("select_topic")).tag("")

                        // For Exams
                        if let chosenExam = exams.first(where: { $0.name == chosenSubject }) {
                            ForEach(chosenExam.topicsArray, id: \.self) { item in
                                Text(item)
                                    .font(.custom("Poppins-Regular", size: 16))
                            }
                        }

                        // For Projects
                        if let chosenProject = projects.first(where: { $0.name == chosenSubject }) {
                            ForEach(chosenProject.topicsArray, id: \.self) { item in
                                Text(item)
                                    .font(.custom("Poppins-Regular", size: 16))
                            }
                        }
                    }
                    .font(.custom("Poppins-Regular", size: 16))
                    .frame(width: 200, height: 100)
                    .clipped()
                    .padding()
                }
                
                Button(LocalizedStringKey("Save")) {
                    let newReport = Report(context: moc)
                    newReport.date = timerStartDate
                    newReport.subjectName = chosenSubject
                    newReport.totalTime = Int16(totalWorkTime)
                    
                    if let chosenSubject = chosenSubject {
                        // Add topics based on whether it's an exam or project
                        if exams.first(where: { $0.name == chosenSubject }) != nil {
                            newReport.desc = !reportDescription.isEmpty ? reportDescription : selectedTopic
                        } else if projects.first(where: { $0.name == chosenSubject }) != nil {
                            newReport.desc = !reportDescription.isEmpty ? reportDescription : selectedTopic
                        }
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
                .font(.custom("Poppins-Regular", size: 18))
                .padding()
                .cornerRadius(10)
            }
            .padding()
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
            .font(.custom("Poppins-Regular", size: 60))
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

        
        DispatchQueue.global(qos: .background).async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTimer()
                }
            }
            RunLoop.current.add(self.timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    private func updateTimer() {
        DispatchQueue.global(qos: .background).async {
            if self.countdownTime > 0 {
                DispatchQueue.main.async {
                    self.countdownTime -= 1
                    if !self.onBreak {
                        self.totalWorkTime += 1
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.handleEndOfInterval()
                }
            }
        }
    }
    
    private func handleEndOfInterval() {
        if onBreak {
            currentInterval += 1
            if currentInterval <= intervalNumber {
                onBreak = false
                countdownTime = intervalTime * 60
                scheduleNotification(message: "starting_next_interval_message")
            } else {
                stopTimer()
                scheduleNotification(message: "timer_is_over_message")
            }
        } else {
            onBreak = true
            countdownTime = breakTime * 60
            scheduleNotification(message: "time_for_break_message")
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
    
    
    private func pauseTimer() {
        timer?.invalidate()
        timerIsPaused = true
    }
    
    private func resumeTimer() {
        timerIsPaused = false
        DispatchQueue.global(qos: .background).async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                DispatchQueue.main.async {
                    if self.countdownTime > 0 {
                        self.countdownTime -= 1
                        if !self.onBreak {
                            self.totalWorkTime += 1
                        }
                    } else {
                        self.handleEndOfInterval()
                    }
                }
            }
            RunLoop.current.add(self.timer!, forMode: .common)
            RunLoop.current.run()
        }
    }
    
    private func timeString(time: Int) -> String {
        if time <= 59 && time > 0 {
               return "1"
           }
        let minutes = Int(ceil(Double(time) / 60.0))
           
        return "\(String(format: "%d", minutes))"
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

import SwiftUI

struct CircularProgressView<Content: View>: View {
    var progress: CGFloat
    var currentInterval: Int
    var intervalNumber: Int
    var content: Content
    var isTimerStarted: Bool
    var actColor: Color
    var onBreak: Bool
    @State private var startAngle: Angle = .degrees(0)
    @State private var endAngle: Angle = .degrees(360)
    
    var body: some View {
        ZStack {
            Circle()
                .fill(actColor.opacity(0.2))
                .frame(width: 320, height: 320)
                .blur(radius: 55)
           
            Circle()
                .fill(Color.bg2)
                .frame(width: 250, height: 250)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(actColor.opacity(onBreak ? 0.5 : 1))
                .rotationEffect(Angle(degrees: 270))
                .frame(width: 250, height: 250)
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            
                .mask(
                    Circle()
                        .frame(width: 250, height: 250)
                )
            
            Circle()
                .fill(Color.clear)
                .frame(width: 180, height: 180)
            
            VStack {
                content
                
            }
            
            if isTimerStarted {
                Text("\(currentInterval) / \(intervalNumber)")
                    .offset(y: -50)
                    .foregroundColor(.white)
                    .opacity(0.5)
                    .font(.custom("Poppins-Regular", size: 17))
                    .padding()
            }
        }
        .edgesIgnoringSafeArea(.all)
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

