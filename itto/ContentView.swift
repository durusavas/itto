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
    var content: Content
   

    var body: some View {
    
        
        ZStack {
            Circle()
                .stroke(lineWidth: 15)
                .opacity(0.3)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.blue)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
            
            content
        }
        .frame(width: 200, height: 200)
        
    }
        
    
}

extension Color {
    static let customBackgroundColor = Color(red: 234 / 255, green: 255 / 255, blue: 184 / 255)
}

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<Subjects>
    
    @State private var interval = 4
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
    
    let sets = [1, 2, 3, 4, 5, 6]
    let times = [1, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    let breakTimes = [1, 5, 10, 15, 20]
    


    
    var body: some View {

            VStack {
                HStack{
                    VStack {
                        Text("Sets:")
                        Picker("Repetitions", selection: $interval) {
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
                
                CircularProgressView(progress: progressValue(), content: timerIsPaused ? AnyView(intervalPicker) : AnyView(countdownView))
                    .padding()
                
                HStack{
                    Picker("Subject", selection: $chosenSubject) {
                        ForEach(subjects) { item in
                            Text(item.name ?? "Unknown").tag(item.name ?? "Unknown")
                        }
                    }
                    
                    
                    NavigationLink(destination: AddSubjectView()) {
                        Text("Add Class")
                            
                        Image(systemName: "plus")
                    }
                    
                } .padding()
                
                HStack{
                    if timerIsPaused && !timerStarted {
                        Button("Start Timer") {
                            startTimer()
                        }     .foregroundColor(.blue)
                            .padding()
                        
                    } else {
                        Button("Stop Timer") {
                            stopTimer()
                            
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                    if timerIsPaused && timerStarted {
                        Button("Resume Timer") {
                            resumeTimer()
                        }
                        .padding()
                    }

                    if(!timerIsPaused){
                        Button("Pause Timer"){
                            pauseTimer()
                        }
                    }
                   
                }
                
            
           
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
                if self.currentInterval < self.interval {
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
        timerEndDate = Date()
        timer?.invalidate()
        countdownTime = 0
        timerIsPaused = true
        timerStarted = false
        let newReport = Report(context: moc)
        newReport.date = timerStartDate
        newReport.subjectName = chosenSubject
        newReport.totalTime = Int16(totalWorkTime)
        if moc.hasChanges {
            do {
                try moc.save()
            } catch {
                // Handle the error, perhaps with an alert to the user
                print("Could not save data: \(error.localizedDescription)")
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
                if self.currentInterval < self.interval {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

