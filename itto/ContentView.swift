//
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


struct CircularProgressView<Content: View>: View {
    var progress: CGFloat
    var currentInterval: Int
    var intervalNumber: Int
    var content: Content
    var isTimerStarted: Bool
    var accentColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 25)
                .opacity(0.1)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round))
                .foregroundColor(accentColor)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
            
            content
            if isTimerStarted{
                Text("\(currentInterval) / \(intervalNumber)") // Display the current set number
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



struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    @FetchRequest(sortDescriptors: []) var exams: FetchedResults<Exams>
    @FetchRequest(sortDescriptors: []) var projects: FetchedResults<Projects>
    
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
    @State private var chosenSubject = ""
    @State private var timerStarted = false
    @State private var navigateToReportView = false
    @State private var selectedTopic = ""
    @State private var showDescSheet = false
    @State private var reportDescription = ""
    @State private var showAddSubjectsView = false
    
    let sets = [1, 2, 3, 4, 5, 6]
    let times = [1, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breakTimes = [1, 5, 10, 15, 20]
    
    init(chosenSubject: String = " ") {
        self._chosenSubject = State(initialValue: chosenSubject)
        requestNotificationPermissions()
    }
    
    
    var body: some View {
        NavigationStack{
            
            VStack {
                if(!timerStarted){
                    HStack{
                        VStack {
                            Text("Sets")
                            Picker("Sets", selection: $intervalNumber) {
                                ForEach(sets, id: \.self) { number in
                                    Text("\(number)")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 100)
                            .clipped()
                        }
                        VStack {
                            Text("Break")
                            Picker("Break", selection: $breakTime) {
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
                
                CircularProgressView(progress: progressValue(), currentInterval: currentInterval, intervalNumber: intervalNumber, content: (!timerStarted && timerIsPaused) ? AnyView(intervalPicker) : AnyView(countdownView), isTimerStarted: timerStarted, accentColor: getColorForSelectedSubject())
                    .padding()
                    .padding()
                
                
                if(!timerStarted){
                    HStack{
                        Picker("Subject", selection: $chosenSubject) {
                            ForEach(filteredSubjects, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }


                        Button(action: {
                            showAddSubjectsView = true
                        }) {
                            HStack {
                                Text("Add Subject")
                                Image(systemName: "plus")
                            }
                        }
                        .padding()

                    } .padding()
                }
                
                VStack{
                    if timerIsPaused && timerStarted {
                        Button("Resume Timer") {
                            resumeTimer()
                        }
                        .padding()
                        .background(.gray.opacity(0.1))
                        .cornerRadius(15)
                        
                    }
                    
                    if(!timerIsPaused){
                        Button("Pause Timer"){
                            pauseTimer()
                        }
                        .padding()
                        
                        .background(.gray.opacity(0.1))
                        .cornerRadius(15)
                    }
                    
                    if timerIsPaused && !timerStarted {
                        Button("Start Timer") {
                            startTimer()
                        }     .foregroundColor(.blue)
                            .padding()
                            .font(.largeTitle)
                            .background(.gray.opacity(0.1))
                            .cornerRadius(10)
                        
                        
                    } else {
                        Button("Stop Timer") {
                            stopTimer()
                            
                            
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .font(.title2)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                    }
                }
            }
        }
        .animation(.easeInOut, value: timerStarted)
        
        .sheet(isPresented: $showDescSheet) { // Present the sheet for entering the description
            descriptionSheet
            
        }
        .sheet(isPresented: $showAddSubjectsView) {
                AddSubjectView() // Assuming you have an AddSubjectView to present
            }
        .onAppear {
            printReportsData()
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
    private func printReportsData() {
        do {
            let reports = try moc.fetch(Report.fetchRequest()) as [Report]
            print("Reports Data:")
            for report in reports {
                print("Date: \(report.date ?? Date()), Subject: \(report.subjectName ?? "Unknown"), Total Time: \(report.totalTime) seconds, Description: \(report.desc ?? "No description")")
            }
        } catch {
            print("Error fetching Reports: \(error)")
        }
    }

    private func resumeTimerIfNeeded() {
            // Resume timer only if it was running and paused
            if !timerStarted && !timerIsPaused {
                resumeTimer()
            }
        }
    private var filteredSubjects: [String] {
        let subjectNames = Set(subjects.compactMap { $0.name })
        let projectNames = Set(projects.compactMap { $0.name })
        return Array(subjectNames.union(projectNames))
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
                print("Notification permissions granted")
            } else if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }
    func scheduleNotification(message: String, soundName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Notification"
        content.body = message
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))

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
            Text("What have you done? ")
                .font(.largeTitle)
                .padding()
            
            TextField("Description", text: $reportDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .padding()
            
            if isExamAndClass {
          
                // Add a conditional Picker for "Exam" category
                Picker("Topics", selection: $selectedTopic) {
                    Text("Select Topic").tag("") // Default empty option
                    if let chosenExam = exams.first(where: { $0.name == chosenSubject }) {
                        // Assuming Exams have a property named 'topics'
                        ForEach(chosenExam.topicsArray, id: \.self) { item in
                            Text(item)
                        }
                    }
                }

    
                .frame(width: 200, height: 100)
                .clipped()
                .padding()
            }
            Button("Save") {
                // Save the report with the description and selected topic (if applicable)
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

                // Check for duplicates before saving
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
            return Color.white // Default color if no subject or project is selected
        }
    }

    
    private var intervalPicker: some View {
        Picker("Interval Time:", selection: $intervalTime) {
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
        timer?.invalidate()
        timerStartDate = Date()

        if timerIsPaused {
            // If the timer was paused, reset countdownTime and totalWorkTime
            countdownTime = onBreak ? breakTime * 60 : intervalTime * 60
            totalWorkTime = 0
            currentInterval = onBreak ? 0 : 1
        }

        timerIsPaused = false
        timerStarted = true

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
                    self.currentInterval += 1
                } else {
                    self.timer?.invalidate()
                 
                }
            }

            // Update the circular view
            self.updateCircularView()
        }
    }


    private func stopTimer() {
        showDescSheet = true
        timerEndDate = Date()
        timer?.invalidate()
        countdownTime = 0
        timerIsPaused = true
        timerStarted = false
        
        let newReport = Report(context: moc)
        newReport.date = timerStartDate
        newReport.subjectName = chosenSubject
        newReport.totalTime = Int16(totalWorkTime)
        
      

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
                            scheduleNotification(message: "Time to take a break!", soundName: "notification_sound.mp3")
                            
                            // If there are more intervals, start the next interval
                            if currentInterval < intervalNumber {
                                onBreak.toggle()
                                countdownTime = intervalTime * 60
                                currentInterval += 1
                            } else {
                                // If all intervals are finished, schedule notification for the end of the whole countdown
                                scheduleNotification(message: "Timer finished!", soundName: "notification_sound.mp3")
                            }
                        } else {
                            // If it's the end of the work interval, schedule notification for the start of the break
                            scheduleNotification(message: "Break started!", soundName: "notification_sound.mp3")
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


