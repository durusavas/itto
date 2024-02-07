//
//  ContentView.swift
//  itto
//
//  Created by Duru SAVAŞ on 17/11/2023.
//
import SwiftUI
import CoreData
import Foundation

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

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    
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
    
    @State private var showDescSheet = false
    @State private var reportDescription = ""
    @State private var showAddSubjectsView = false
    
    let sets = [1, 2, 3, 4, 5, 6]
    let times = [20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breakTimes = [1, 5, 10, 15, 20]
    
    var body: some View {
        NavigationView{
            VStack {
                if(!timerStarted){
                    HStack{
                        VStack {
                            Text("Sets:")
                            Picker("Repetitions", selection: $intervalNumber) {
                                ForEach(sets, id: \.self) { number in
                                    Text("\(number)")
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100, height: 100)
                            .clipped()
                        }
                        VStack {
                            Text("Break Time:")
                            Picker("Break Time:", selection: $breakTime) {
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
                            ForEach(subjects) { item in
                                Text(item.name ?? "Unknown").tag(item.name ?? "Unknown")
                            }
                        }
                        Button() {
                            showAddSubjectsView = true
                            Text("Add Class")
                            Image(systemName: "plus")
                        }
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
        .sheet(isPresented: $showingAddSubjectView) {
                AddSubjectView() // Assuming you have an AddSubjectView to present
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
            
            Button("Save") {
                // Save the report with the description
                let newReport = Report(context: moc)
                newReport.date = timerStartDate
                newReport.subjectName = chosenSubject
                newReport.totalTime = Int16(totalWorkTime)
                newReport.desc = reportDescription  // Save the description
                
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
        guard let subjectColorString = subjects.first(where: { $0.name == chosenSubject })?.color else {
            return Color.white // Default color if no subject is selected or color is not set
        }
        return subjectColorString.toColor()
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
        countdownTime = intervalTime * 60
        timerIsPaused = false
        onBreak = false
        currentInterval = 1
        totalWorkTime = 0
        timerStarted = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.countdownTime > 0 {
                self.countdownTime -= 1
                if !self.onBreak {
                    self.totalWorkTime += 1
                }
            } else {
                // if there is tjrs des repetiton a faire switch to break
                if self.currentInterval < self.intervalNumber {
                    self.onBreak.toggle()
                    self.countdownTime = self.onBreak ? self.breakTime * 60 : self.intervalTime * 60
                    if !self.onBreak { // If the next interval is a work interval, increment the interval count.
                        self.currentInterval += 1
                    }
                } else {
                    self.timer?.invalidate()
                    
                }
            }
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


