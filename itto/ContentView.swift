//  ContentView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//

import SwiftUI
import CoreData
import Foundation
import UserNotifications
import UIKit
import Observation

@Observable
final class TimerManager {
    var intervalNumber = 4
    var intervalTime = 30
    var breakTime = 5
    
    var countdownTime = 0
    var timerIsPaused = true
    var onBreak = false
    var currentInterval = 1
    var totalWorkTime = 0
    var timerStarted = false
    var chosenSubject: String?
    var timerStartDate: Date?
    var sessionCompleted = false

    private var timer: Timer?

    private let stateKey = "itto_timer_state_v1"
    private let pendingSessionKey = "itto_pending_session_v1"
    
    init() {
        loadDefaults()
        restoreState()
    }
    
    func loadDefaults() {
        let ud = UserDefaults.standard
        if ud.integer(forKey: "defaultInterval") > 0 {
            intervalTime = ud.integer(forKey: "defaultInterval")
        }
        if ud.integer(forKey: "defaultBreak") > 0 {
            breakTime = ud.integer(forKey: "defaultBreak")
        }
    }
    
    func start() {
        timerStartDate = Date()
        timer?.invalidate()
        currentInterval = 1
        onBreak = false
        countdownTime = intervalTime * 60
        timerIsPaused = false
        timerStarted = true
        totalWorkTime = 0
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        scheduleNextNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        
        saveState()
    }
    
    func pause() {
        timer?.invalidate()
        timerIsPaused = true
        saveState()
    }
    
    func resume() {
        timerIsPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        saveState()
    }
    
    func stop() {
        timer?.invalidate()
        timerStarted = false
        timerIsPaused = true
        countdownTime = 0
        clearState()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    private func tick() {
        if countdownTime > 0 {
            countdownTime -= 1
            if !onBreak {
                totalWorkTime += 1
            }
            if countdownTime % 5 == 0 {
                saveState()
            }
        } else {
            handleEndOfInterval()
        }
    }
    
    private func handleEndOfInterval() {
        if onBreak {
            currentInterval += 1
            if currentInterval <= intervalNumber {
                onBreak = false
                countdownTime = intervalTime * 60
                scheduleNextNotification()
            } else {
                // Save session data before stop() so it survives app kills
                savePendingSession()
                stop()
                scheduleNotification(message: "timer_is_over_message", delay: 1)
                sessionCompleted = true
                return
            }
        } else {
            onBreak = true
            countdownTime = breakTime * 60
            // "time_for_break_message" is already scheduled by scheduleNextNotification() at interval start —
            // don't schedule it again here or the user gets two break notifications.
            // Only announce "starting next interval" when there actually is one.
            if currentInterval < intervalNumber {
                scheduleNotification(message: "starting_next_interval_message", delay: TimeInterval(breakTime * 60))
            }
        }
        saveState()
    }
    
    private func scheduleNextNotification() {
        scheduleNotification(message: "time_for_break_message", delay: TimeInterval(intervalTime * 60))
    }
    
    private func scheduleNotification(message: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("timer_notification_title", comment: "Timer Notification")
        content.body = NSLocalizedString(message, comment: "Notification message")
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 0.5), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func saveState() {
        let state: [String: Any] = [
            "intervalNumber": intervalNumber,
            "intervalTime": intervalTime,
            "breakTime": breakTime,
            "chosenSubject": chosenSubject ?? "",
            "timerStarted": timerStarted,
            "timerIsPaused": timerIsPaused,
            "onBreak": onBreak,
            "currentInterval": currentInterval,
            "totalWorkTime": totalWorkTime,
            "timerStartDate": timerStartDate?.timeIntervalSince1970 ?? 0,
            "countdownTime": countdownTime
        ]
        if let data = try? JSONSerialization.data(withJSONObject: state) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }
    
    private func restoreState() {
        // If a session completed while the app was backgrounded/killed, surface the save sheet
        if let data = UserDefaults.standard.data(forKey: pendingSessionKey),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let startTs = dict["startDate"] as? TimeInterval, startTs > 0 {
                timerStartDate = Date(timeIntervalSince1970: startTs)
            }
            totalWorkTime = dict["workTime"] as? Int ?? 0
            let subj = dict["subject"] as? String ?? ""
            chosenSubject = subj.isEmpty ? nil : subj
            sessionCompleted = true
            return
        }

        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        if let startTs = dict["timerStartDate"] as? TimeInterval, startTs > 0 {
            let start = Date(timeIntervalSince1970: startTs)
            if Date().timeIntervalSince(start) > 3 * 3600 {
                clearState()
                return
            }
        }
        
        intervalNumber = dict["intervalNumber"] as? Int ?? 4
        intervalTime = dict["intervalTime"] as? Int ?? 30
        breakTime = dict["breakTime"] as? Int ?? 5
        let subj = dict["chosenSubject"] as? String ?? ""
        chosenSubject = subj.isEmpty ? nil : subj
        timerStarted = dict["timerStarted"] as? Bool ?? false
        timerIsPaused = dict["timerIsPaused"] as? Bool ?? true
        onBreak = dict["onBreak"] as? Bool ?? false
        currentInterval = dict["currentInterval"] as? Int ?? 1
        totalWorkTime = dict["totalWorkTime"] as? Int ?? 0
        countdownTime = dict["countdownTime"] as? Int ?? 0
        
        if let startTs = dict["timerStartDate"] as? TimeInterval, startTs > 0 {
            timerStartDate = Date(timeIntervalSince1970: startTs)
        }
        
        // If the timer was running when the app was killed, restart the tick loop
        if timerStarted && !timerIsPaused {
            DispatchQueue.main.async { UIApplication.shared.isIdleTimerDisabled = true }
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { self?.tick() }
            }
        }
    }
    
    private func clearState() {
        UserDefaults.standard.removeObject(forKey: stateKey)
    }

    // Persists the completed session so the save sheet can appear even after an app relaunch
    private func savePendingSession() {
        let pending: [String: Any] = [
            "startDate": timerStartDate?.timeIntervalSince1970 ?? 0,
            "workTime": totalWorkTime,
            "subject": chosenSubject ?? ""
        ]
        if let data = try? JSONSerialization.data(withJSONObject: pending) {
            UserDefaults.standard.set(data, forKey: pendingSessionKey)
        }
    }

    func clearPendingSession() {
        UserDefaults.standard.removeObject(forKey: pendingSessionKey)
        sessionCompleted = false
    }
}

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
    
    @State private var timerManager = TimerManager()
    @State private var selectedAccentColor: Color = Color.white
    @State private var navigateToReportView = false
    @State private var selectedTopic = ""
    @State private var showDescSheet = false
    @State private var reportDescription = ""
    @State private var showAddSubjectsView = false
    @State private var isSavingReport = false
    @State private var chosenSubject: String? = nil
    
    private func filteredSubjects() -> [String] {
        let subjectNames = Set(subjects.compactMap { $0.name })
        let projectNames = Set(projects.compactMap { $0.name })
        let examNames = Set(exams.compactMap { $0.examName })
        return Array(subjectNames.union(projectNames).union(examNames))
    }
    
    private func setPreset(sets: Int, interval: Int, breakTime: Int) {
        Haptics.impact(.light)
        timerManager.intervalNumber = sets
        timerManager.intervalTime = interval
        timerManager.breakTime = breakTime
    }
    
    let sets = [1, 2, 3, 4, 5, 6]
    let times = [1, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breakTimes = [1, 5, 10, 15, 20]
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if !granted, let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
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
                
                if !timerManager.timerStarted {
                    VStack {
                        HStack(spacing: 12) {
                            Button("25/5") { setPreset(sets: 4, interval: 25, breakTime: 5) }
                            Button("50/10") { setPreset(sets: 2, interval: 50, breakTime: 10) }
                            Button("Pomodoro") { setPreset(sets: 4, interval: 25, breakTime: 5) }
                        }
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        
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
                                    Picker(LocalizedStringKey("Sets"), selection: $timerManager.intervalNumber) {
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
                                    Picker(LocalizedStringKey("Interval"), selection: $timerManager.intervalTime) {
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
                                    Picker(LocalizedStringKey("Break"), selection: $timerManager.breakTime) {
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
                            Haptics.impact(.medium)
                            timerManager.start()
                            selectedAccentColor = getColorForSelectedSubject()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color.white)
                                .padding()
                                .cornerRadius(100)
                                .opacity(0.8)
                         
                        }
                        .accessibilityLabel("Start timer session")
                        .accessibilityHint("Begins the Pomodoro focus timer with current settings")
                    }
                    .padding()
                    .transition(.asymmetric(insertion: .opacity.combined(with: .slide), removal: .opacity.combined(with: .slide)))
                   
                }
                
                if timerManager.timerStarted {
                    CircularProgressView(
                        progress: progressValue(),
                        currentInterval: timerManager.currentInterval,
                        intervalNumber: timerManager.intervalNumber,
                        content: countdownView,
                        isTimerStarted: timerManager.timerStarted,
                        actColor: selectedAccentColor,
                        onBreak: timerManager.onBreak
                    )
                    
                    .padding()
                }
                
                if !timerManager.timerStarted {
                    HStack {
                        Picker(LocalizedStringKey("Subject"), selection: $chosenSubject) {
                            Text(LocalizedStringKey("Choose")).tag(nil as String?)
                            ForEach(filteredSubjects(), id: \.self) { name in
                                Text(name).tag(name as String?)
                                    .font(.custom("Poppins-Regular", size: 17))
                            }
                        }
                        .onChange(of: chosenSubject) { oldValue, newValue in
                            timerManager.chosenSubject = chosenSubject
                            if !timerManager.timerStarted {
                                self.selectedAccentColor = getColorForSelectedSubject()
                            }
                        }
                    }
                    .padding()
                    Spacer()
                }
                
                HStack {
                    if timerManager.timerIsPaused && timerManager.timerStarted {
                        Button(action: {
                            Haptics.impact(.medium)
                            timerManager.resume()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .padding()
                                .opacity(0.8)
                        }
                    }
                    
                    if !timerManager.timerIsPaused {
                        Button(action: {
                            Haptics.impact(.light)
                            timerManager.pause()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.largeTitle)
                                .padding()
                                .foregroundColor(.white)
                                .opacity(0.8)
                        }
                    }
                    
                    if !timerManager.timerIsPaused && timerManager.timerStarted {
                        Button(action: {
                            Haptics.impact(.heavy)
                            timerManager.stop()
                            showDescSheet = true
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
                if let firstSubject = filteredSubjects().first, chosenSubject == nil {
                    self.chosenSubject = firstSubject
                }
                if let cs = timerManager.chosenSubject {
                    chosenSubject = cs
                }
                if timerManager.timerStarted {
                    selectedAccentColor = getColorForSelectedSubject()
                }
            }
        }
        .animation(.easeInOut, value: timerManager.timerStarted)
        .onChange(of: timerManager.sessionCompleted) { _, completed in
            if completed { showDescSheet = true }
        }
        .sheet(isPresented: $showDescSheet, onDismiss: {
            timerManager.clearPendingSession()
        }) {
            descriptionSheet
        }
        .sheet(isPresented: $showAddSubjectsView) {
            AddSubjectView()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Manager restores state on init; accent color refresh handled in onAppear
        }
    }
    
    var isExamAndClass: Bool {
        let subjectExists = subjects.contains(where: { $0.name == chosenSubject })
        let examExists = exams.contains(where: { $0.examName == chosenSubject || $0.name == chosenSubject })
        return subjectExists && examExists
    }
    
    private func getDailySubjectColors(for date: Date) -> [Color] {
        let calendar = Calendar.current
        let filteredSubjects = dailySubjects.filter { calendar.isDate($0.date ?? Date(), inSameDayAs: date) }
        let colors = filteredSubjects.compactMap { $0.color?.toColor() }
        return colors.isEmpty ? [Color.gray, Color.blue] : colors
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

                        if let chosenExam = exams.first(where: { $0.examName == chosenSubject || $0.name == chosenSubject }) {
                            ForEach(chosenExam.topicsArray, id: \.self) { item in
                                Text(item)
                                    .font(.custom("Poppins-Regular", size: 16))
                            }
                        }

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
                    Haptics.notification(.success)
                    let newReport = Report(context: moc)
                    newReport.date = timerManager.timerStartDate
                    newReport.subjectName = chosenSubject
                    newReport.totalTime = Int16(timerManager.totalWorkTime)
                    
                    if let chosenSubject = chosenSubject {
                        if exams.first(where: { $0.examName == chosenSubject || $0.name == chosenSubject }) != nil {
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
        } else if let exam = exams.first(where: { $0.examName == chosenSubject || $0.name == chosenSubject }) {
            return exam.color?.toColor() ?? Color.white
        } else if let project = projects.first(where: { $0.name == chosenSubject }) {
            return project.color?.toColor() ?? Color.white
        } else {
            return Color.white
        }
    }
    
    private var countdownView: some View {
        Text(timeString(time: timerManager.countdownTime))
            .font(.custom("Poppins-Regular", size: 60))
    }
    
    private func progressValue() -> CGFloat {
        let totalDuration = timerManager.onBreak ? timerManager.breakTime * 60 : timerManager.intervalTime * 60
        return totalDuration > 0 ? CGFloat(timerManager.countdownTime) / CGFloat(totalDuration) : 0
    }
    
    private func timeString(time: Int) -> String {
        if time <= 0 { return "0" }
        let minutes = Int(ceil(Double(time) / 60.0))
        return "\(minutes)"
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
        let rgbValues = components.compactMap { component -> CGFloat? in
            let parts = component.split(separator: ":")
            guard parts.count == 2 else { return nil }
            let value = parts[1]
            return CGFloat(Double(value) ?? 0) / 255.0
        }
        guard rgbValues.count >= 3 else {
            return Color.gray
        }
        return Color(red: rgbValues[0], green: rgbValues[1], blue: rgbValues[2])
    }
}
